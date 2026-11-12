-- Starting seeds: all digital products. Safe to re-run.
INSERT INTO seeds (source, value) VALUES
  -- sellers: what sells, what buyers ask for
  ('reddit','Etsy'), ('reddit','EtsySellers'), ('reddit','Gumroad'), ('reddit','printables'),
  ('reddit','digitalproducts'), ('reddit','passive_income'), ('reddit','SideProject'),
  -- templates and productivity
  ('reddit','Notion'), ('reddit','NotionTemplates'), ('reddit','canva'), ('reddit','excel'),
  ('reddit','googlesheets'), ('reddit','productivity'), ('reddit','ObsidianMD'),
  -- planners and life organisation
  ('reddit','planners'), ('reddit','bulletjournal'), ('reddit','ADHD'), ('reddit','personalfinance'),
  ('reddit','budget'), ('reddit','weddingplanning'), ('reddit','Mommit'),
  -- education
  ('reddit','Teachers'), ('reddit','homeschool'), ('reddit','GetStudying'), ('reddit','languagelearning'),
  -- creators and assets
  ('reddit','graphic_design'), ('reddit','photography'), ('reddit','Lightroom'), ('reddit','WeAreTheMusicMakers'),
  ('reddit','gamedev'), ('reddit','web_design'), ('reddit','ChatGPT'),
  -- small business and freelancers
  ('reddit','smallbusiness'), ('reddit','Entrepreneur'), ('reddit','freelance'), ('reddit','socialmediamarketing')
ON CONFLICT (source, value) DO NOTHING;

-- YouTube search queries: videos whose comments reveal buyer and seller needs.
INSERT INTO seeds (source, value) VALUES
  ('youtube','what digital products sell on etsy'),
  ('youtube','digital products to sell'),
  ('youtube','notion template ideas'),
  ('youtube','printable planner etsy'),
  ('youtube','canva templates to sell'),
  ('youtube','gumroad digital product'),
  ('youtube','spreadsheet template business'),
  ('youtube','sell ebook online'),
  ('youtube','lightroom presets sell'),
  ('youtube','teacher printables tpt')
ON CONFLICT (source, value) DO NOTHING;

-- Buyer-side YouTube queries (2026-11-12): what end customers ask for, not sellers.
INSERT INTO seeds (source, value) VALUES
  ('youtube','best notion template for students'),
  ('youtube','budget spreadsheet template'),
  ('youtube','adhd planner'),
  ('youtube','wedding planning checklist'),
  ('youtube','teacher classroom resources'),
  ('youtube','meal planner printable'),
  ('youtube','resume template'),
  ('youtube','small business templates')
ON CONFLICT (source, value) DO NOTHING;

-- Low-yield seller queries, kept for history but no longer collected.
UPDATE seeds SET active = false WHERE source = 'youtube'
  AND value IN ('spreadsheet template business', 'notion template ideas', 'printable planner etsy');

-- 2026-11-12: wedding checklist returned off-topic drama, teacher resources almost no comments.
INSERT INTO seeds (source, value) VALUES
  ('youtube','wedding budget spreadsheet'),
  ('youtube','homeschool planner')
ON CONFLICT (source, value) DO NOTHING;
UPDATE seeds SET active = false WHERE source = 'youtube'
  AND value IN ('wedding planning checklist', 'teacher classroom resources');
