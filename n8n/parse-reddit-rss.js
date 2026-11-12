// Parse Reddit Atom feeds into raw_posts rows. Usernames are deliberately not stored.
const decode = (s = '') => s
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d)).replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&');
const strip = (html) => decode(decode(html).replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
const pick = (xml, re) => (xml.match(re) || [])[1] || '';

const rows = [];
for (const item of $input.all()) {
  const feed = item.json.data;
  if (typeof feed !== 'string') continue;
  for (const [, entry] of feed.matchAll(/<entry>([\s\S]*?)<\/entry>/g)) {
    const id = pick(entry, /<id>([^<]+)<\/id>/);
    if (!id.startsWith('t3_')) continue;
    const body = strip(pick(entry, /<content[^>]*>([\s\S]*?)<\/content>/))
      .replace(/\s*submitted by\s+\/u\/[\s\S]*$/i, '').replace(/\/?u\/[\w-]+/g, '[user]').trim();
    rows.push({ json: {
      source: 'reddit',
      external_id: id,
      channel: pick(entry, /<category term="([^"]+)"/),
      url: pick(entry, /<link href="([^"]+)"/),
      title: strip(pick(entry, /<title>([\s\S]*?)<\/title>/)),
      body: body.slice(0, 5000),
      posted_at: pick(entry, /<published>([^<]+)<\/published>/) || pick(entry, /<updated>([^<]+)<\/updated>/),
    }});
  }
}
return rows;
