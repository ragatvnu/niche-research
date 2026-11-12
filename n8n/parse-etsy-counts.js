// Total active listings per seed: how crowded the keyword is.
const seeds = $('Get seeds').all();
return $input.all().map((item, i) => ({ json: { seed: seeds[i].json.seed, total_count: item.json.count ?? null } }));
