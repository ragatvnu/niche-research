// One item per video found by the search, carrying the query that found it.
const out = [];
for (const [i, item] of $input.all().entries()) {
  const query = $('Get queries').all()[i]?.json.query;
  for (const v of item.json.items || []) {
    if (!v.id?.videoId) continue;
    out.push({ json: { query, video_id: v.id.videoId, video_title: v.snippet?.title ?? '' } });
  }
}
return out;
