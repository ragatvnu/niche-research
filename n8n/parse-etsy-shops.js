// Unique shops from this run; only shop-level totals, no owner names kept beyond the shop name.
const out = [];
for (const item of $input.all()) {
  const s = item.json;
  if (!s.shop_id) continue;
  out.push({ json: {
    shop_id: s.shop_id,
    shop_name: s.shop_name,
    transaction_sold_count: s.transaction_sold_count,
    review_count: s.review_count,
    review_average: s.review_average,
    listing_active_count: s.listing_active_count,
    created_at: s.create_date ? new Date(s.create_date * 1000).toISOString() : null,
  }});
}
return out;
