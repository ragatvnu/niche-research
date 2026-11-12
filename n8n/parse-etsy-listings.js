// One row per listing. Etsy listings hold no buyer data.
const out = [];
const seeds = $('Get seeds').all();
$input.all().forEach((item, i) => {
  const seed = seeds[i].json.seed;
  (item.json.results || []).forEach((l, rank) => {
    const p = l.price || {};
    out.push({ json: {
      seed, rank: rank + 1,
      listing_id: l.listing_id,
      shop_id: l.shop_id,
      title: l.title,
      price: p.divisor ? p.amount / p.divisor : null,
      currency: p.currency_code,
      num_favorers: l.num_favorers,
      views: l.views,
      quantity: l.quantity,
      is_digital: l.is_digital ?? (l.type === 'download'),
      created_at: l.created_timestamp ? new Date(l.created_timestamp * 1000).toISOString() : null,
      tags: l.tags || [],
      url: l.url ? l.url.split('?')[0] : null,
    }});
  });
});
return out;
