// Turn YouTube commentThreads responses into raw_posts rows. Author names are deliberately not stored.
const videos = Object.fromEntries($('Split videos').all().map((v) => [v.json.video_id, v.json]));
const rows = [];
for (const item of $input.all()) {
  for (const t of item.json.items || []) {
    const c = t.snippet?.topLevelComment?.snippet;
    if (!c?.textDisplay) continue;
    const text = c.textDisplay.replace(/@[\w.-]+/g, '[user]').replace(/\s+/g, ' ').trim();
    if (text.length < 25) continue; // skip "great video!" noise
    rows.push({ json: {
      source: 'youtube',
      external_id: t.id,
      channel: videos[c.videoId]?.query ?? null,
      url: `https://www.youtube.com/watch?v=${c.videoId}&lc=${t.id}`,
      title: videos[c.videoId]?.video_title ?? null,
      body: text.slice(0, 5000),
      score: c.likeCount ?? 0,
      num_comments: t.snippet.totalReplyCount ?? 0,
      posted_at: c.publishedAt,
    }});
  }
}
return rows;
