-- Niche research schema. Safe to re-run.

-- Everything collected, from every platform.
CREATE TABLE IF NOT EXISTS raw_posts (
  id            BIGSERIAL PRIMARY KEY,
  source        TEXT NOT NULL,              -- reddit | pinterest | etsy | gumroad
  external_id   TEXT NOT NULL,              -- the platform's own id, for dedupe
  channel       TEXT,                       -- subreddit, search keyword, category
  url           TEXT,
  title         TEXT,
  body          TEXT,
  score         INTEGER,                    -- upvotes / saves / reviews
  num_comments  INTEGER,
  price         NUMERIC(10,2),              -- marketplaces only
  posted_at     TIMESTAMPTZ,
  collected_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at  TIMESTAMPTZ,                -- set once AI has extracted needs
  raw           JSONB,
  UNIQUE (source, external_id)
);
CREATE INDEX IF NOT EXISTS raw_posts_unprocessed ON raw_posts (collected_at) WHERE processed_at IS NULL;
CREATE INDEX IF NOT EXISTS raw_posts_source_posted ON raw_posts (source, posted_at);

-- Buyer needs extracted by AI from raw posts.
CREATE TABLE IF NOT EXISTS needs (
  id            BIGSERIAL PRIMARY KEY,
  raw_post_id   BIGINT NOT NULL REFERENCES raw_posts(id) ON DELETE CASCADE,
  topic         TEXT NOT NULL,              -- e.g. "adhd planner"
  category      TEXT,                       -- printable | template | ebook | course | asset | software | prompt
  problem       TEXT NOT NULL,              -- the need in one sentence
  buyer_type    TEXT,                       -- e.g. "college student"
  intent        TEXT,                       -- request | complaint | willing_to_pay | recommendation
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS needs_topic_created ON needs (topic, created_at);

-- Weekly score per niche, combining all phases.
CREATE TABLE IF NOT EXISTS niche_scores (
  id              BIGSERIAL PRIMARY KEY,
  week            DATE NOT NULL,            -- Monday of the week
  topic           TEXT NOT NULL,
  need_score      NUMERIC,                  -- Reddit mentions and growth
  search_score    NUMERIC,                  -- Pinterest / search demand
  payment_score   NUMERIC,                  -- Etsy / Gumroad proof of sales
  competition     NUMERIC,
  total           NUMERIC,
  notes           TEXT,
  UNIQUE (week, topic)
);

-- What to collect: subreddits, keywords, categories.
CREATE TABLE IF NOT EXISTS seeds (
  id        SERIAL PRIMARY KEY,
  source    TEXT NOT NULL,
  value     TEXT NOT NULL,
  active    BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (source, value)
);

-- Pinterest Trends: weekly search interest for keywords matching our seeds.
CREATE TABLE IF NOT EXISTS pinterest_trends (
  id            BIGSERIAL PRIMARY KEY,
  collected_on  DATE NOT NULL DEFAULT current_date,
  region        TEXT NOT NULL,              -- US, GB+IE, CA, AU+NZ
  seed          TEXT NOT NULL,              -- the include_keywords filter used
  keyword       TEXT NOT NULL,
  pct_wow       INTEGER,                    -- growth week over week (10001 = new)
  pct_mom       INTEGER,
  pct_yoy       INTEGER,
  last_value    INTEGER,                    -- latest weekly volume, normalised 0-100
  time_series   JSONB,
  UNIQUE (collected_on, region, keyword)
);
CREATE INDEX IF NOT EXISTS pinterest_trends_keyword ON pinterest_trends (keyword, collected_on);

-- Etsy: weekly snapshot of active listings per seed keyword (proof of payment + competition).
CREATE TABLE IF NOT EXISTS etsy_listings (
  id            BIGSERIAL PRIMARY KEY,
  collected_on  DATE NOT NULL DEFAULT current_date,
  seed          TEXT NOT NULL,              -- search keyword used
  rank          INTEGER,                    -- position in Etsy relevance results
  listing_id    BIGINT NOT NULL,
  shop_id       BIGINT,
  title         TEXT,
  price         NUMERIC(10,2),
  currency      TEXT,
  num_favorers  INTEGER,
  views         INTEGER,
  quantity      INTEGER,
  is_digital    BOOLEAN,
  created_at    TIMESTAMPTZ,                -- listing creation date
  tags          TEXT[],
  url           TEXT,
  UNIQUE (collected_on, seed, listing_id)
);
CREATE INDEX IF NOT EXISTS etsy_listings_seed ON etsy_listings (seed, collected_on);

-- Etsy search totals per seed (how crowded a keyword is).
CREATE TABLE IF NOT EXISTS etsy_search_counts (
  collected_on  DATE NOT NULL DEFAULT current_date,
  seed          TEXT NOT NULL,
  total_count   INTEGER,
  PRIMARY KEY (collected_on, seed)
);

-- Etsy shops seen in results; transaction_sold_count is the sales proxy.
CREATE TABLE IF NOT EXISTS etsy_shops (
  collected_on           DATE NOT NULL DEFAULT current_date,
  shop_id                BIGINT NOT NULL,
  shop_name              TEXT,
  transaction_sold_count INTEGER,
  review_count           INTEGER,
  review_average         NUMERIC(3,2),
  listing_active_count   INTEGER,
  created_at             TIMESTAMPTZ,
  PRIMARY KEY (collected_on, shop_id)
);
