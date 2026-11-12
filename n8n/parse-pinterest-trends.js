// One row per trending keyword; Pinterest returns only keywords, no user data.
const out = [];
const seeds = $('Get seeds').all();
$input.all().forEach((item, i) => {
  const { seed, region } = seeds[i].json;
  for (const t of item.json.trends || []) {
    const series = t.time_series || {};
    const dates = Object.keys(series).sort();
    out.push({ json: {
      region, seed,
      keyword: t.keyword,
      pct_wow: t.pct_growth_wow,
      pct_mom: t.pct_growth_mom,
      pct_yoy: t.pct_growth_yoy,
      last_value: dates.length ? series[dates[dates.length - 1]] : null,
      time_series: JSON.stringify(series),
    }});
  }
});
return out;
