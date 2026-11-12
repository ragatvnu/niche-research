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
