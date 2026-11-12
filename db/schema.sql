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

-- Groups need topics into niches and links each niche to its search seeds.
-- Rows live only in the database while the repo is public (they reveal findings).
CREATE TABLE IF NOT EXISTS niche_map (
  topic           TEXT PRIMARY KEY,         -- needs.topic
  niche           TEXT NOT NULL,
  pinterest_seed  TEXT,
  etsy_seed       TEXT
);

ALTER TABLE niche_scores ADD COLUMN IF NOT EXISTS mentions    INTEGER;  -- end-buyer needs, all time
ALTER TABLE niche_scores ADD COLUMN IF NOT EXISTS mentions_7d INTEGER;  -- end-buyer needs, this week
ALTER TABLE niche_scores ADD COLUMN IF NOT EXISTS checks      INTEGER;  -- need/search/payment checks passed (0-3)

-- (No ';' inside the function body: n8n splits queries on it.)
-- Weekly score per niche. Each part is 0-100; missing data counts as 0.
--   need        2 points per end-buyer mention (50 mentions = 100); sellers excluded
--   search      average Pinterest volume of the niche's seed keywords, latest week
--   payment     log scale of the median shop sales behind the top 25 Etsy results
--   competition log scale of Etsy's total listing count for the seed
-- LEAST() ignores NULLs, so COALESCE goes inside it. Niches named '... (dropped)' are skipped.
--   total       0.4 need + 0.3 search + 0.3 payment - 0.2 competition
-- Checks: need >= 60 (30 mentions), search >= 40, payment >= 50.
CREATE OR REPLACE FUNCTION refresh_niche_scores(p_week DATE) RETURNS INTEGER AS $$
WITH buyer_needs AS (
  SELECT COALESCE(m.niche, n.topic) AS niche, n.created_at
  FROM needs n LEFT JOIN niche_map m ON m.topic = n.topic
  WHERE COALESCE(n.buyer_type, '') !~* 'seller|author'
    AND n.created_at < p_week + 7
    AND COALESCE(m.niche, '') NOT LIKE '%(dropped)'
),
need AS (
  SELECT niche, count(*) AS mentions,
         count(*) FILTER (WHERE created_at >= p_week) AS mentions_7d
  FROM buyer_needs GROUP BY niche
),
seeds AS (
  SELECT DISTINCT niche, pinterest_seed, etsy_seed FROM niche_map
),
search AS (
  SELECT s.niche, avg(t.last_value) AS v
  FROM seeds s JOIN pinterest_trends t ON t.seed = s.pinterest_seed
  WHERE t.collected_on = (SELECT max(collected_on) FROM pinterest_trends WHERE collected_on < p_week + 7)
  GROUP BY s.niche
),
etsy_day AS (
  SELECT max(collected_on) AS d FROM etsy_listings WHERE collected_on < p_week + 7
),
payment AS (
  SELECT s.niche, percentile_cont(0.5) WITHIN GROUP (ORDER BY sh.transaction_sold_count) AS v
  FROM seeds s
  JOIN etsy_listings l ON l.seed = s.etsy_seed AND l.rank <= 25 AND l.collected_on = (SELECT d FROM etsy_day)
  JOIN etsy_shops sh ON sh.shop_id = l.shop_id AND sh.collected_on = l.collected_on
  GROUP BY s.niche
),
competition AS (
  SELECT s.niche, max(c.total_count) AS v
  FROM seeds s JOIN etsy_search_counts c ON c.seed = s.etsy_seed AND c.collected_on = (SELECT d FROM etsy_day)
  GROUP BY s.niche
),
scored AS (
  SELECT n.niche, n.mentions, n.mentions_7d,
         (LEAST(100, 2 * n.mentions))::numeric AS need_score,
         (LEAST(100, COALESCE(se.v, 0)))::numeric AS search_score,
         (LEAST(100, 20 * log(COALESCE(p.v, 0) + 1)))::numeric AS payment_score,
         (LEAST(100, 20 * log(COALESCE(c.v, 0) + 1)))::numeric AS competition
  FROM need n
  LEFT JOIN search se ON se.niche = n.niche
  LEFT JOIN payment p ON p.niche = n.niche
  LEFT JOIN competition c ON c.niche = n.niche
),
upsert AS (
  INSERT INTO niche_scores (week, topic, mentions, mentions_7d, need_score, search_score, payment_score, competition, total, checks)
  SELECT p_week, niche, mentions, mentions_7d,
         round(need_score, 1), round(search_score, 1), round(payment_score, 1), round(competition, 1),
         round(0.4 * need_score + 0.3 * search_score + 0.3 * payment_score - 0.2 * competition, 1),
         (need_score >= 60)::int + (search_score >= 40)::int + (payment_score >= 50)::int
  FROM scored
  ON CONFLICT (week, topic) DO UPDATE SET
    mentions = EXCLUDED.mentions, mentions_7d = EXCLUDED.mentions_7d,
    need_score = EXCLUDED.need_score, search_score = EXCLUDED.search_score,
    payment_score = EXCLUDED.payment_score, competition = EXCLUDED.competition,
    total = EXCLUDED.total, checks = EXCLUDED.checks
  RETURNING 1
)
SELECT count(*)::int FROM upsert
$$ LANGUAGE sql;

-- Top 10 per week with rank, for the "stable for 3 weeks" rule.
CREATE OR REPLACE VIEW niche_report AS
SELECT week, rank() OVER (PARTITION BY week ORDER BY total DESC) AS rank,
       topic AS niche, total, need_score, search_score, payment_score, competition, mentions, mentions_7d, checks
FROM niche_scores;
