#!/usr/bin/env node
// Workflow Kit - search scholarly literature in several free databases at once and write ONE merged candidates table.
// It never downloads PDFs (that is lit-fetch.mjs) and never scrapes Google Scholar / SINTA / Garuda (they forbid bots):
// for those it prints search links for the USER to open in a browser.
//
// Usage:
//   node .agents/scripts/lit-search.mjs "<query>" [options]
//     --from 2019 --to 2025     publication years (inclusive)
//     --limit 25                results per source (max 100)
//     --sources openalex,crossref,s2,arxiv   default: openalex,crossref,s2 (+arxiv with --preprints)
//     --preprints               also search arXiv (preprints: NOT peer reviewed, mark them in the notes)
//     --oa                      only open-access results (OpenAlex/S2 filter; Crossref/arXiv results are kept but marked)
//     --lang id|en              OpenAlex language filter (ISO 639-1)
//     --sort relevance|citations|year   default relevance (order of first appearance, OpenAlex first)
//     --out research/search     output folder (default research/search)
//     --json                    print the merged list as JSON instead of the summary
//
// Output: research/search/<date>-<slug>.md (table + abstracts) and .json (input for lit-fetch.mjs), and one line in
// research/SEARCH-LOG.md (date, query, filters, hits per source) - the log is needed for the method chapter (PRISMA).
//
// Keys (optional, set as environment variables, NEVER written in files that go to git):
//   OPENALEX_API_KEY   free key from https://openalex.org/settings/api (without it: small daily budget shared per IP)
//   S2_API_KEY         Semantic Scholar key (without it: often "429 Too Many Requests"; the script retries once)
//   RESEARCH_EMAIL     the user's email for the Crossref "polite pool" (ask the user; do not invent one)
//
// Read .agents/knowledge/research-sources.md for which databases count as reputable (Scopus/SINTA/DOAJ) and why.

import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const opt = (name, def) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : def;
};
const flag = (name) => argv.includes(`--${name}`);
const VALUED = ['from', 'to', 'limit', 'sources', 'lang', 'sort', 'out'];
const query = argv.find((a, i) => !a.startsWith('--') && !(i > 0 && VALUED.includes(argv[i - 1].slice(2))));
if (!query) {
  console.error('usage: lit-search.mjs "<query>" [--from Y] [--to Y] [--limit N] [--sources a,b] [--preprints] [--oa] [--lang id] [--sort relevance|citations|year] [--out DIR] [--json]');
  process.exit(2);
}

const FROM = opt('from'), TO = opt('to');
const LIMIT = Math.min(parseInt(opt('limit', '25'), 10) || 25, 100);
const OA_ONLY = flag('oa');
const LANG = opt('lang');
const SORT = opt('sort', 'relevance');
const OUT = opt('out', path.join('research', 'search'));
const SOURCES = opt('sources', flag('preprints') ? 'openalex,crossref,s2,arxiv' : 'openalex,crossref,s2').split(',');
const EMAIL = process.env.RESEARCH_EMAIL || '';
const UA = `WorkflowKit-lit-search/0.6${EMAIL ? ` (mailto:${EMAIL})` : ''}`;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getJson(url, headers = {}, retries = 1) {
  const res = await fetch(url, { headers: { 'User-Agent': UA, ...headers } });
  if (res.status === 429 && retries > 0) {
    await sleep(3500);
    return getJson(url, headers, retries - 1);
  }
  if (res.status === 429) throw new Error('HTTP 429 rate limit');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

const normDoi = (d) => (d || '').toLowerCase().replace(/^https?:\/\/(dx\.)?doi\.org\//, '').trim() || null;
const normTitle = (t) => (t || '').toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, ' ').trim();
const authorList = (names) => (names.length > 3 ? `${names.slice(0, 3).join(', ')} et al.` : names.join(', '));

function abstractFromIndex(inv) {
  if (!inv) return '';
  const words = [];
  for (const [w, positions] of Object.entries(inv)) for (const p of positions) words[p] = w;
  return words.filter(Boolean).join(' ');
}

// Each source returns records of one shape.
function record(r) {
  return {
    title: r.title || '(no title)', authors: r.authors || '', year: r.year || null, venue: r.venue || '',
    issn: r.issn || '', type: r.type || '', doi: normDoi(r.doi), citations: r.citations ?? null,
    oa: r.oa || 'unknown', pdf: r.pdf || '', landing: r.landing || '', retracted: !!r.retracted,
    doaj: r.doaj ?? null, abstract: (r.abstract || '').replace(/\s+/g, ' ').trim(), arxiv: r.arxiv || '',
    found_in: [r.source],
  };
}

async function openalex() {
  const f = [`title_and_abstract.search:${query.replace(/[,:]/g, ' ')}`];
  if (FROM) f.push(`from_publication_date:${FROM}-01-01`);
  if (TO) f.push(`to_publication_date:${TO}-12-31`);
  if (OA_ONLY) f.push('is_oa:true');
  if (LANG) f.push(`language:${LANG}`);
  const sel = 'id,doi,display_name,publication_year,cited_by_count,open_access,best_oa_location,primary_location,authorships,is_retracted,type,abstract_inverted_index';
  const p = new URLSearchParams({ filter: f.join(','), 'per-page': String(LIMIT), select: sel });
  if (process.env.OPENALEX_API_KEY) p.set('api_key', process.env.OPENALEX_API_KEY);
  const data = await getJson(`https://api.openalex.org/works?${p}`);
  return (data.results || []).map((w) => {
    const src = w.primary_location?.source || {};
    return record({
      source: 'openalex', title: w.display_name, year: w.publication_year, doi: w.doi, citations: w.cited_by_count,
      authors: authorList((w.authorships || []).map((a) => a.author?.display_name).filter(Boolean)),
      venue: src.display_name, issn: src.issn_l || (src.issn || [])[0], type: w.type,
      oa: w.open_access?.oa_status, pdf: w.best_oa_location?.pdf_url, landing: w.best_oa_location?.landing_page_url || w.primary_location?.landing_page_url,
      retracted: w.is_retracted, doaj: src.is_in_doaj, abstract: abstractFromIndex(w.abstract_inverted_index),
    });
  });
}

async function crossref() {
  const f = [];
  if (FROM) f.push(`from-pub-date:${FROM}`);
  if (TO) f.push(`until-pub-date:${TO}`);
  const p = new URLSearchParams({
    'query.bibliographic': query, rows: String(LIMIT),
    select: 'DOI,title,author,issued,container-title,ISSN,is-referenced-by-count,type,abstract,update-to,URL',
  });
  if (f.length) p.set('filter', f.join(','));
  if (EMAIL) p.set('mailto', EMAIL);
  const data = await getJson(`https://api.crossref.org/works?${p}`);
  return (data.message?.items || []).map((w) => record({
    source: 'crossref', title: (w.title || [])[0], year: w.issued?.['date-parts']?.[0]?.[0], doi: w.DOI,
    authors: authorList((w.author || []).map((a) => [a.given, a.family].filter(Boolean).join(' ') || a.name).filter(Boolean)),
    venue: (w['container-title'] || [])[0], issn: (w.ISSN || [])[0], type: w.type, citations: w['is-referenced-by-count'],
    landing: w.URL, abstract: (w.abstract || '').replace(/<[^>]+>/g, ' '),
    retracted: (w['update-to'] || []).some((u) => /retraction/i.test(u.type || '')),
  }));
}

async function semanticScholar() {
  const p = new URLSearchParams({
    query, limit: String(Math.min(LIMIT, 100)),
    fields: 'title,year,externalIds,citationCount,openAccessPdf,venue,authors,publicationTypes,isOpenAccess,abstract',
  });
  if (FROM || TO) p.set('year', `${FROM || ''}-${TO || ''}`);
  if (OA_ONLY) p.set('openAccessPdf', '');
  const headers = process.env.S2_API_KEY ? { 'x-api-key': process.env.S2_API_KEY } : {};
  const data = await getJson(`https://api.semanticscholar.org/graph/v1/paper/search?${p}`, headers);
  return (data.data || []).map((w) => record({
    source: 's2', title: w.title, year: w.year, doi: w.externalIds?.DOI, citations: w.citationCount,
    authors: authorList((w.authors || []).map((a) => a.name)), venue: w.venue, type: (w.publicationTypes || [])[0],
    oa: w.isOpenAccess ? 'oa' : 'closed', pdf: w.openAccessPdf?.url, abstract: w.abstract,
    arxiv: w.externalIds?.ArXiv,
  }));
}

async function arxiv() {
  const terms = query.split(/\s+/).filter(Boolean).map((t) => `all:${t}`).join(' AND ');
  const p = new URLSearchParams({ search_query: terms, max_results: String(LIMIT) });
  const res = await fetch(`https://export.arxiv.org/api/query?${p}`, { headers: { 'User-Agent': UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const xml = await res.text();
  const tag = (s, t) => (s.match(new RegExp(`<${t}[^>]*>([\\s\\S]*?)</${t}>`)) || [])[1]?.trim() || '';
  return [...xml.matchAll(/<entry>([\s\S]*?)<\/entry>/g)].map(([, e]) => {
    const id = tag(e, 'id').replace(/^https?:\/\/arxiv\.org\/abs\//, '');
    const year = parseInt(tag(e, 'published').slice(0, 4), 10) || null;
    return record({
      source: 'arxiv', title: tag(e, 'title').replace(/\s+/g, ' '), year, arxiv: id.replace(/v\d+$/, ''),
      authors: authorList([...e.matchAll(/<name>([^<]+)<\/name>/g)].map((m) => m[1])),
      venue: 'arXiv (preprint)', type: 'preprint', oa: 'green', pdf: `https://arxiv.org/pdf/${id}`,
      landing: `https://arxiv.org/abs/${id}`, doi: (e.match(/<arxiv:doi[^>]*>([^<]+)</) || [])[1],
      abstract: tag(e, 'summary'),
    });
  }).filter((r) => (!FROM || (r.year && r.year >= +FROM)) && (!TO || (r.year && r.year <= +TO)));
}

const RUNNERS = { openalex, crossref, s2: semanticScholar, arxiv };

function merge(lists) {
  const out = [];
  const byKey = new Map();
  for (const list of lists) {
    for (const r of list) {
      const keys = [r.doi && `doi:${r.doi}`, r.arxiv && `arxiv:${r.arxiv}`, `t:${normTitle(r.title)}:${r.year || ''}`].filter(Boolean);
      const hit = keys.map((k) => byKey.get(k)).find(Boolean);
      if (!hit) {
        out.push(r);
        keys.forEach((k) => byKey.set(k, r));
        continue;
      }
      for (const [k, v] of Object.entries(r)) {
        if (k === 'found_in') hit.found_in = [...new Set([...hit.found_in, ...v])];
        else if (k === 'citations') hit.citations = Math.max(hit.citations ?? 0, v ?? 0);
        else if (k === 'retracted') hit.retracted = hit.retracted || v;
        else if (k === 'oa') { if (hit.oa === 'unknown' || hit.oa === 'closed') hit.oa = v === 'unknown' ? hit.oa : v; }
        else if (!hit[k] && v) hit[k] = v;
      }
      keys.forEach((k) => byKey.set(k, hit));
    }
  }
  return out;
}

const cell = (s) => String(s ?? '').replace(/\|/g, '\\|').replace(/\s+/g, ' ').trim();
const slug = (s) => s.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 50);

function manualLinks() {
  const q = encodeURIComponent(query);
  return [
    `- Google Scholar (user opens it; bots are blocked): https://scholar.google.com/scholar?q=${q}${FROM ? `&as_ylo=${FROM}` : ''}${TO ? `&as_yhi=${TO}` : ''}`,
    `- Garuda (Indonesian journals, Kemdiktisaintek): https://garuda.kemdiktisaintek.go.id/documents?q=${q}`,
    `- SINTA (journal accreditation S1-S6, check a journal here): https://sinta.kemdiktisaintek.go.id/journals?q=${q}`,
    `- DOAJ (open-access journals that passed DOAJ checks): https://doaj.org/search/articles?ref=homepage&source=%7B%22query%22%3A%7B%22query_string%22%3A%7B%22query%22%3A%22${q}%22%7D%7D%7D`,
    `- Scopus (needs campus login): https://www.scopus.com/results/results.uri?s=TITLE-ABS-KEY(${q})`,
  ].join('\n');
}

async function main() {
  const lists = [];
  const counts = {};
  for (const s of SOURCES) {
    const run = RUNNERS[s];
    if (!run) { counts[s] = 'unknown source'; continue; }
    try {
      const r = await run();
      counts[s] = r.length;
      lists.push(r);
    } catch (e) {
      counts[s] = `error (${e.message})`;
    }
    if (s === 's2' || s === 'arxiv') await sleep(1100); // both ask for about 1 request per second
  }
  let rows = merge(lists);
  if (SORT === 'citations') rows.sort((a, b) => (b.citations ?? -1) - (a.citations ?? -1));
  if (SORT === 'year') rows.sort((a, b) => (b.year ?? 0) - (a.year ?? 0));

  if (flag('json')) {
    console.log(JSON.stringify({ query, counts, rows }, null, 2));
    return;
  }

  const date = new Date().toISOString().slice(0, 10);
  const base = `${date}-${slug(query) || 'search'}`;
  fs.mkdirSync(OUT, { recursive: true });
  const filters = [FROM && `from ${FROM}`, TO && `to ${TO}`, OA_ONLY && 'OA only', LANG && `lang ${LANG}`].filter(Boolean).join(', ') || 'none';
  const countText = Object.entries(counts).map(([k, v]) => `${k}: ${v}`).join(', ');

  const lines = [
    `# Search: ${query}`, '',
    `Date: ${date}. Sources: ${countText}. Filters: ${filters}. Merged (duplicates removed by DOI/title): ${rows.length}.`, '',
    'Columns: OA = open-access status (gold/green/hybrid/bronze/diamond = free to read; closed = paywalled; unknown = not reported).',
    'DOAJ = journal listed in DOAJ. RETRACTED = do NOT cite. "preprint" = not peer reviewed. Journal quality is NOT shown here:',
    'check each journal by ISSN in SINTA / Scimago / Scopus (.agents/knowledge/research-sources.md -> "Is this journal OK?").', '',
    '| # | Year | Title | Authors | Venue (ISSN) | Type | Cited | OA | DOI / link | Flags |',
    '|---|---|---|---|---|---|---|---|---|---|',
  ];
  rows.forEach((r, i) => {
    const flags = [r.retracted && '**RETRACTED**', r.type === 'preprint' && 'preprint', r.doaj && 'DOAJ', r.pdf && 'pdf'].filter(Boolean).join(' ');
    const link = r.doi ? `https://doi.org/${r.doi}` : r.landing || '';
    lines.push(`| ${i + 1} | ${r.year ?? ''} | ${cell(r.title)} | ${cell(r.authors)} | ${cell(r.venue)}${r.issn ? ` (${r.issn})` : ''} | ${cell(r.type)} | ${r.citations ?? ''} | ${r.oa} | ${link} | ${flags} |`);
  });
  lines.push('', '## Search manually as well (the AI cannot query these; the user opens the links)', '', manualLinks(), '', '## Abstracts', '');
  rows.forEach((r, i) => {
    lines.push(`**${i + 1}. ${r.title}** (${r.year ?? 'n.d.'})`, '', r.abstract ? r.abstract.slice(0, 1200) : '_No abstract in the databases. Read the paper landing page._', '');
  });

  const mdPath = path.join(OUT, `${base}.md`);
  fs.writeFileSync(mdPath, `${lines.join('\n')}\n`);
  fs.writeFileSync(path.join(OUT, `${base}.json`), JSON.stringify({ query, date, filters, counts, rows }, null, 2));

  const logPath = path.join(path.dirname(OUT), 'SEARCH-LOG.md');
  if (!fs.existsSync(logPath)) {
    fs.writeFileSync(logPath, '# Search log\n\nEvery search, in order. Needed for the method chapter (PRISMA: records identified per database).\n\n| Date | Query | Filters | Hits per source | Merged | File |\n|---|---|---|---|---|---|\n');
  }
  fs.appendFileSync(logPath, `| ${date} | ${cell(query)} | ${filters} | ${countText} | ${rows.length} | ${path.basename(mdPath)} |\n`);

  console.log(`lit-search: ${rows.length} candidates (${countText})`);
  console.log(`  table: ${mdPath}`);
  console.log(`  json:  ${mdPath.replace(/\.md$/, '.json')} (for lit-fetch.mjs)`);
  console.log(`  log:   ${logPath}`);
  const errs = Object.entries(counts).filter(([, v]) => typeof v === 'string');
  if (errs.length) console.log(`  warning: ${errs.map(([k, v]) => `${k} ${v}`).join('; ')} (set the API key env var or retry later)`);
  const retracted = rows.filter((r) => r.retracted).length;
  if (retracted) console.log(`  ${retracted} RETRACTED paper(s) in the list: never cite them.`);
  if (!EMAIL) console.log('  tip: set RESEARCH_EMAIL (the user\'s email, ask them) for faster Crossref and for Unpaywall in lit-fetch.');
}

main().catch((e) => { console.error(`lit-search: ${e.message}`); process.exit(1); });
