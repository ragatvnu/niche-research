# Niche Research: Rules

Goal: find in-demand digital product niches from real data (what people want, search and pay for), then run a 30-day test product. Limit: 6 weeks of research.

## 1. Data ethics (promised to Reddit, applies to every source)
- Read-only. Never post, comment, vote, message or follow anyone.
- Never store usernames or author names. Replace `@name` and `/u/name` with `[user]`.
- Never republish, share or sell raw posts or comments. Only aggregated topics and trends leave the database.
- Never use collected data to train AI models.
- Raw posts are deleted after 90 days (nightly job in the Reddit workflow).
- Respect rate limits; never work around blocks (no proxies, no fake user agents). If a source blocks us, pause it.
- While this repo is public: no research findings in commits or issues.

## 2. Secrets
- Keys live only in `.env` (gitignored). Claude never reads `.env` directly or prints a value.
- Load one variable at a time: `grep -m1 '^NAME=' .env | cut -d= -f2-`. Never `source` the whole file.
- Service keys used by workflows are stored as n8n credentials.
- Never reuse login/OAuth tokens from other projects.

## 3. Infrastructure
- n8n: https://n8n.trenoxahq.com (Coolify project "n8n"). Postgres: Coolify project "Niche research", credential "Niche research DB" (id bIyoGDLnutKs8Cap).
- The database is private. To run SQL: create a temporary n8n workflow (Webhook -> Postgres), call it once, then delete it.
- Workflows are versioned in `n8n/`. Edit the file, then update n8n via the API.

| Source | Workflow | Schedule | Status |
|---|---|---|---|
| Reddit RSS | oQyPfpHryaFcmt7H | every 3h | paused: server IP gets 429; waiting for Data API approval |
| YouTube comments | Qcrw9sH0KXkFKRhb | every 12h | live, ~2,200 of 10,000 quota units/day |

## 4. Analysis (done by Claude in a session, no AI API key)
Run when the user asks ("do the research"):
1. Export unprocessed rows that look like needs (questions, "is there", "I need", "can't find", "would pay", "struggling"...).
2. Read them and group into topics. Skip spam, self-promotion, and comments about the video itself.
3. Insert into `needs`: `topic` (short, lowercase, reuse existing names), `category` (printable | template | ebook | course | asset | software | prompt | other), `problem` (one sentence), `buyer_type`, `intent` (request | complaint | willing_to_pay | recommendation).
4. Mark every exported row `processed_at = now()`, including skipped ones.
5. Delete any local export files.
6. Report to the user: new topics, biggest topics, anything growing.

Keep in mind who is talking: YouTube "how to sell" videos attract sellers, not end buyers. Tag `buyer_type` honestly and look for end-buyer queries too.

## 5. Scoring and decision
- A niche needs 30-50+ mentions before it counts; 4+ weekly data points before calling it "growing".
- Weekly score in `niche_scores`: need (mentions + growth) + search demand (Pinterest/Trends) + proof of payment (Etsy/Gumroad sales) - competition.
- Pick a niche when the top 5-10 stay stable for 3 weekly reports and it passes 2 of 3 checks (need, search, payment).
- Then: 30-day test product on Gumroad. Pivot rule: no sales and fewer than 100 subscribers after 90 days.

## 6. Working style
- Track work in GitHub Issues (one milestone per phase). Commit workflow and SQL changes.
- Push with system git and the gh token helper (snap gh cannot push).
- Tell the user when it is a good moment to clear the session, after progress is saved.
