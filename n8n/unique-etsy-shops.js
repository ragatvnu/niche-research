// Shops behind the top 25 results per seed, deduplicated.
const ids = new Set();
for (const item of $input.all()) if (item.json.rank <= 25 && item.json.shop_id) ids.add(item.json.shop_id);
return [...ids].map(shop_id => ({ json: { shop_id } }));
