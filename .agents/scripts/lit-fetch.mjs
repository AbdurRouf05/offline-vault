#!/usr/bin/env node
// Workflow Kit - add papers to the research library: metadata -> BibTeX in research/refs.bib, the LEGAL open-access PDF
// -> research/sources/<key>.pdf, and the bookkeeping files library.md / to-download.md.
//
// Usage:
//   node .agents/scripts/lit-fetch.mjs <id> [<id> ...]        id = DOI (10.xxxx/...), https://doi.org/..., or arXiv id
//   node .agents/scripts/lit-fetch.mjs --search research/search/<file>.json --pick 1,3,7   rows from lit-search.mjs
//   node .agents/scripts/lit-fetch.mjs --inbox                PDFs the USER put in research/inbox/ (paywalled papers
//                                                            they got legally): finds each DOI, adds the entry, moves
//                                                            the file to research/sources/<key>.pdf
//   node .agents/scripts/lit-fetch.mjs <id> --file <path.pdf> attach a PDF you already have to that id
//   Options: --no-pdf (metadata only)  --dir research (base folder)
//
// Rules this script enforces (do not work around them):
//   - Only open-access copies are downloaded: arXiv, OpenAlex/Unpaywall OA locations (publisher OA, repositories).
//     Paywalled papers go to research/to-download.md with LEGAL ways to get them. Never use pirate sites.
//   - Every downloaded PDF is checked: it must start with %PDF, and its first pages must contain the DOI / arXiv id or
//     most of the title words. Otherwise it is saved as <key>.CHECK.pdf with status "pdf-check" (wrong file risk).
//   - Duplicates (same DOI) are not added twice; citation keys are unique (authorYEARword, then a/b/c).
//
// Env (optional, never commit them): RESEARCH_EMAIL (the user's email, needed for Unpaywall; ask the user),
// OPENALEX_API_KEY. Needs Python + pymupdf for --inbox and for the PDF check (node .agents/scripts/tools-check.mjs).

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const VALUED = ['search', 'pick', 'file', 'dir'];
const opt = (n) => { const i = argv.indexOf(`--${n}`); return i >= 0 ? argv[i + 1] : undefined; };
const flag = (n) => argv.includes(`--${n}`);
const ids = argv.filter((a, i) => !a.startsWith('--') && !(i > 0 && VALUED.includes(argv[i - 1].slice(2))));

const BASE = opt('dir') || 'research';
const P = {
  bib: path.join(BASE, 'refs.bib'), sources: path.join(BASE, 'sources'), inbox: path.join(BASE, 'inbox'),
  lib: path.join(BASE, 'library.json'), libMd: path.join(BASE, 'library.md'), todo: path.join(BASE, 'to-download.md'),
};
const EMAIL = process.env.RESEARCH_EMAIL || '';
const UA = `WorkflowKit-lit-fetch/0.6${EMAIL ? ` (mailto:${EMAIL})` : ''}`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

if (!ids.length && !flag('inbox') && !opt('search')) {
  console.error('usage: lit-fetch.mjs <doi|arxiv-id> ... | --search FILE.json --pick 1,3 | --inbox  [--file PDF] [--no-pdf] [--dir research]');
  process.exit(2);
}

// ---------- identifiers ----------
const normDoi = (d) => (d || '').trim().replace(/^https?:\/\/(dx\.)?doi\.org\//i, '').replace(/^doi:\s*/i, '').toLowerCase() || null;
function parseId(raw) {
  const s = raw.trim();
  const ax = s.match(/^(?:arxiv:)?(\d{4}\.\d{4,5})(v\d+)?$/i) || s.match(/arxiv\.org\/(?:abs|pdf)\/(\d{4}\.\d{4,5})/i);
  if (ax) return { arxiv: ax[1], doi: `10.48550/arxiv.${ax[1]}` };
  const doi = normDoi(s);
  if (doi && /^10\.\d{4,9}\//.test(doi)) {
    const a = doi.match(/^10\.48550\/arxiv\.(\d{4}\.\d{4,5})/);
    return { doi, arxiv: a ? a[1] : null };
  }
  return null;
}

// ---------- HTTP ----------
async function getJson(url, headers = {}) {
  const res = await fetch(url, { headers: { 'User-Agent': UA, ...headers }, redirect: 'follow', signal: AbortSignal.timeout(45000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

async function cslFor(doi) {
  // DOI content negotiation works for Crossref AND DataCite (arXiv, Zenodo) DOIs.
  return getJson(`https://doi.org/${encodeURIComponent(doi).replace(/%2F/g, '/')}`, { Accept: 'application/vnd.citationstyles.csl+json' });
}

async function oaPdfCandidates(id) {
  const urls = [];
  if (id.arxiv) urls.push({ url: `https://arxiv.org/pdf/${id.arxiv}`, via: 'arXiv' });
  try {
    const p = new URLSearchParams({ select: 'doi,best_oa_location,locations' });
    if (process.env.OPENALEX_API_KEY) p.set('api_key', process.env.OPENALEX_API_KEY);
    const w = await getJson(`https://api.openalex.org/works/doi:${id.doi}?${p}`);
    if (normDoi(w.doi) === id.doi) { // OpenAlex sometimes returns a different work for a DOI: ignore it then
      for (const loc of [w.best_oa_location, ...(w.locations || [])]) {
        if (loc?.is_oa && loc.pdf_url) urls.push({ url: loc.pdf_url, via: `OpenAlex (${loc.source?.display_name || loc.raw_type || 'OA copy'})` });
      }
    }
  } catch { /* not in OpenAlex */ }
  const zen = id.doi.match(/^10\.5281\/zenodo\.(\d+)$/);
  if (zen) {
    try { // Zenodo: open repository with a public API listing the record's files
      const z = await getJson(`https://zenodo.org/api/records/${zen[1]}`);
      for (const f of z.files || []) if (/\.pdf$/i.test(f.key) && f.links?.self) urls.push({ url: f.links.self, via: 'Zenodo' });
    } catch { /* record restricted or removed */ }
  }
  if (EMAIL) {
    try {
      const u = await getJson(`https://api.unpaywall.org/v2/${id.doi}?email=${encodeURIComponent(EMAIL)}`);
      for (const loc of [u.best_oa_location, ...(u.oa_locations || [])]) {
        if (loc?.url_for_pdf) urls.push({ url: loc.url_for_pdf, via: `Unpaywall (${loc.host_type || 'OA'})` });
      }
    } catch { /* not in Unpaywall */ }
  }
  const seen = new Set();
  return urls.filter((u) => !seen.has(u.url) && seen.add(u.url));
}

async function download(url) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA, Accept: 'application/pdf,application/octet-stream;q=0.9,*/*;q=0.8' }, redirect: 'follow', signal: AbortSignal.timeout(90000) });
    if (!res.ok) return { error: `HTTP ${res.status}` };
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.subarray(0, 5).toString('latin1') !== '%PDF-') return { error: 'not a PDF (login page or bot check)' };
    if (buf.length < 15000) return { error: 'PDF too small' };
    return { buf };
  } catch (e) {
    return { error: e.name === 'TimeoutError' ? 'timeout' : e.message };
  }
}

// ---------- PDF check via read-doc.py --probe ----------
let PY;
function python() {
  if (PY !== undefined) return PY;
  PY = null;
  for (const c of process.platform === 'win32' ? [['python'], ['py', '-3'], ['python3']] : [['python3'], ['python']]) {
    const r = spawnSync(c[0], [...c.slice(1), '--version'], { encoding: 'utf8', windowsHide: true });
    if (r.status === 0) { PY = c; break; }
  }
  return PY;
}
function probe(file) {
  const py = python();
  if (!py) return null;
  const r = spawnSync(py[0], [...py.slice(1), '-X', 'utf8', path.join(HERE, 'read-doc.py'), file, '--probe'], { encoding: 'utf8', windowsHide: true, timeout: 60000 });
  try { return JSON.parse((r.stdout || '').split('\n').find((l) => l.startsWith('{'))); } catch { return null; }
}
const words = (t) => (t || '').toLowerCase().normalize('NFKD').replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter((w) => w.length > 3);
function pdfMatches(file, id, title) {
  const pr = probe(file);
  if (!pr || pr.error) return { ok: null, why: pr?.error || 'no python/pymupdf: PDF not checked' };
  if (pr.dois.some((d) => normDoi(d) === id.doi)) return { ok: true, why: 'DOI found in PDF' };
  if (id.arxiv && pr.arxiv === id.arxiv) return { ok: true, why: 'arXiv id found in PDF' };
  const want = [...new Set(words(title))];
  const have = new Set(words(pr.first_page));
  const share = want.length ? want.filter((w) => have.has(w)).length / want.length : 0;
  if (share >= 0.7) return { ok: true, why: `title words on page 1 (${Math.round(share * 100)}%)` };
  return { ok: false, why: `DOI not found and only ${Math.round(share * 100)}% of title words on page 1` };
}

// ---------- BibTeX ----------
const first = (v) => (Array.isArray(v) ? v[0] : v) || '';
const clean = (s) => String(s || '').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
const texEsc = (s) => clean(s).replace(/([&%#_])/g, '\\$1');
const STOP = new Set(['a', 'an', 'the', 'of', 'on', 'in', 'for', 'and', 'to', 'with', 'at', 'by', 'from', 'is', 'are', 'dan', 'di', 'yang', 'untuk', 'dari', 'pada', 'dengan', 'ke', 'terhadap', 'dalam', 'sebagai']);
const ascii = (s) => (s || '').normalize('NFKD').replace(/[^A-Za-z0-9]/g, '').toLowerCase();
const yearOf = (c) => (c.issued || c['published-print'] || c['published-online'] || c.created)?.['date-parts']?.[0]?.[0] || 'nd';

function baseKey(c) {
  const a = (c.author || [])[0] || {};
  const who = ascii(a.family || a.literal || a.name || first(c['container-title']) || 'anon').slice(0, 20) || 'anon';
  const word = (clean(first(c.title)).split(/\s+/).map(ascii).find((w) => w && !STOP.has(w)) || 'x').slice(0, 15);
  return `${who}${yearOf(c)}${word}`;
}

const TYPE = {
  'article-journal': 'article', 'journal-article': 'article', 'paper-conference': 'inproceedings', 'proceedings-article': 'inproceedings',
  book: 'book', monograph: 'book', 'edited-book': 'book', chapter: 'incollection', 'book-chapter': 'incollection',
  report: 'report', thesis: 'thesis', dissertation: 'thesis', dataset: 'dataset',
};

const REPOSITORY = /^(zenodo|figshare|osf|osf preprints|researchgate|ssrn|arxiv)$/i;

function toBib(key, c, id) {
  // A repository (Zenodo, Figshare, OSF...) is not a journal, even if the DOI metadata says "article-journal".
  const repo = [first(c['container-title']), c.publisher].find((v) => REPOSITORY.test(clean(v)));
  const type = repo ? 'misc' : TYPE[c.type] || 'misc';
  const authors = (c.author || []).map((a) => (a.family ? `${a.family}${a.given ? `, ${a.given}` : ''}` : `{${a.literal || a.name}}`)).filter(Boolean);
  const f = [
    ['author', authors.map(texEsc).join(' and ')],
    ['title', `{${texEsc(first(c.title))}}`],
    [repo ? '' : type === 'article' ? 'journal' : type === 'inproceedings' || type === 'incollection' ? 'booktitle' : '', texEsc(first(c['container-title']))],
    ['year', String(yearOf(c)).replace('nd', '')],
    ['volume', c.volume], ['number', c.issue], ['pages', (c.page || '').replace(/-/g, '--')],
    ['publisher', type === 'article' || repo ? '' : texEsc(c.publisher)],
    ['howpublished', repo ? texEsc(repo) : ''],
    ['issn', first(c.ISSN)], ['doi', id.doi], ['url', id.doi ? `https://doi.org/${id.doi}` : c.URL],
  ];
  if (id.arxiv) f.push(['eprinttype', 'arxiv'], ['eprint', id.arxiv], ['note', 'Preprint']);
  const body = f.filter(([k, v]) => k && v).map(([k, v]) => `  ${k.padEnd(10)} = {${v}}`).join(',\n');
  return `@${type}{${key},\n${body}\n}\n`;
}

function readBib() {
  const text = fs.existsSync(P.bib) ? fs.readFileSync(P.bib, 'utf8') : '';
  const keys = new Set(), byDoi = new Map();
  for (const chunk of text.split(/\n(?=@)/)) {
    const k = chunk.match(/@\w+\s*\{\s*([^,\s]+)\s*,/);
    if (!k) continue;
    keys.add(k[1]);
    const d = chunk.match(/\bdoi\s*=\s*[{"]([^}"]+)[}"]/i);
    if (d) byDoi.set(normDoi(d[1]), k[1]);
  }
  return { keys, byDoi };
}

// ---------- library bookkeeping ----------
const loadLib = () => (fs.existsSync(P.lib) ? JSON.parse(fs.readFileSync(P.lib, 'utf8')) : {});
function saveLib(lib) {
  fs.writeFileSync(P.lib, JSON.stringify(lib, null, 2));
  const rows = Object.entries(lib).sort((a, b) => a[0].localeCompare(b[0]));
  const md = [
    '# Library', '',
    'Made by lit-fetch.mjs (do not edit by hand; the data is in library.json). Status: pdf = verified PDF in sources/;',
    'pdf-check = a PDF was found but it may be the WRONG paper (open it and check title/authors); to-download = no legal',
    'free copy found, see to-download.md; meta-only = metadata only (--no-pdf). Reading status lives in the note cards.', '',
    '| Key | Year | Title | Status | File | DOI |', '|---|---|---|---|---|---|',
    ...rows.map(([k, e]) => `| ${k} | ${e.year || ''} | ${(e.title || '').replace(/\|/g, '\\|')} | ${e.status} | ${e.file || ''} | ${e.doi || ''} |`),
  ];
  fs.writeFileSync(P.libMd, `${md.join('\n')}\n`);
  const todo = rows.filter(([, e]) => e.status === 'to-download');
  const t = [
    '# To download (by the user)', '',
    'No legal free copy was found for these. Try the legal routes below in order, save the PDF in research/inbox/ (any',
    'file name), then tell the AI: "sudah, cek inbox" (it runs: node .agents/scripts/lit-fetch.mjs --inbox).', '',
    'Legal routes: (1) open the DOI link: some publishers show a free PDF to readers but not to scripts; (2) Google Scholar',
    'link: look for a [PDF] link on the right or "All versions" (author repository copies); (3) ask the author by email',
    '(corresponding author on the publisher page) or ResearchGate "Request full-text": authors may share their own paper;',
    '(4) campus library / e-journal access (Scopus, ScienceDirect, ProQuest, EBSCO via the campus login); (5) Perpusnas',
    'e-resources (free membership: https://e-resources.perpusnas.go.id); (6) interlibrary loan via the campus library.',
    'Not allowed in this kit: pirate sites (Sci-Hub, LibGen and similar), see .agents/knowledge/research-sources.md.', '',
    ...(todo.length ? todo.flatMap(([k, e]) => [
      `## ${k}`, '', `${e.title} (${e.year || 'n.d.'})`, '',
      `- DOI: ${e.doi ? `https://doi.org/${e.doi}` : '-'}`,
      `- Google Scholar: https://scholar.google.com/scholar?q=${encodeURIComponent(`"${e.title}"`)}`,
      `- Tried (no legal PDF or blocked): ${(e.tried || []).join('; ') || 'no open-access location known'}`, '',
    ]) : ['Nothing to download.']),
  ];
  fs.writeFileSync(P.todo, `${t.join('\n')}\n`);
}

// ---------- one item ----------
async function addItem(id, lib, bib, { file, noPdf } = {}) {
  let csl;
  try { csl = await cslFor(id.doi); } catch (e) { return { line: `FAIL  ${id.doi}: metadata not found (${e.message}). Check the DOI.` }; }
  const title = clean(first(csl.title));
  let key = bib.byDoi.get(id.doi) || Object.keys(lib).find((k) => lib[k].doi === id.doi);
  const isNew = !key;
  if (isNew) {
    const b = baseKey(csl);
    key = b;
    for (let i = 0; bib.keys.has(key) || lib[key]; i++) key = `${b}${'bcdefghijklmnop'[i]}`;
    fs.mkdirSync(path.dirname(P.bib), { recursive: true });
    fs.appendFileSync(P.bib, `\n${toBib(key, csl, id)}`);
    bib.keys.add(key); bib.byDoi.set(id.doi, key);
  }
  const e = lib[key] || { title, year: yearOf(csl), doi: id.doi, arxiv: id.arxiv || undefined, added: new Date().toISOString().slice(0, 10) };
  lib[key] = e;
  if (e.status === 'pdf' && e.file && fs.existsSync(e.file) && !file) return { key, line: `skip  ${key}: already in library with a verified PDF` };

  fs.mkdirSync(P.sources, { recursive: true });
  const dest = path.join(P.sources, `${key}.pdf`);
  const place = (from, how) => {
    const m = pdfMatches(from, id, title);
    const target = m.ok === false ? path.join(P.sources, `${key}.CHECK.pdf`) : dest;
    if (path.resolve(from) !== path.resolve(target)) fs.renameSync(from, target);
    e.file = target.split(path.sep).join('/');
    e.status = m.ok === false ? 'pdf-check' : 'pdf';
    e.check = m.why;
    return `${e.status === 'pdf' ? 'ok   ' : 'CHECK'} ${key}: ${how} -> ${e.file} (${m.why})`;
  };

  if (file) return { key, line: place(file, 'given file') };
  if (noPdf) { e.status = e.status || 'meta-only'; return { key, line: `meta  ${key}: ${title.slice(0, 70)}` }; }

  const cands = await oaPdfCandidates(id);
  e.tried = [];
  for (const c of cands) {
    const r = await download(c.url);
    if (r.error) { e.tried.push(`${c.via}: ${r.error}`); continue; }
    const tmp = `${dest}.part`;
    fs.writeFileSync(tmp, r.buf);
    return { key, line: place(tmp, c.via) };
  }
  e.status = 'to-download';
  return { key, line: `todo  ${key}: no legal free PDF (${cands.length ? `${cands.length} OA link(s) failed` : 'paywalled'}) -> to-download.md` };
}

// ---------- main ----------
async function main() {
  const lib = loadLib();
  const bib = readBib();
  const out = [];
  const noPdf = flag('no-pdf');

  const queue = [];
  for (const raw of ids) {
    const id = parseId(raw);
    if (!id) { out.push(`FAIL  "${raw}": not a DOI or arXiv id`); continue; }
    queue.push({ id, file: opt('file') });
  }
  if (opt('search')) {
    const data = JSON.parse(fs.readFileSync(opt('search'), 'utf8'));
    const picks = (opt('pick') || '').split(',').map((s) => parseInt(s, 10)).filter(Boolean);
    if (!picks.length) { console.error('lit-fetch: --search needs --pick 1,3,5 (row numbers from the search table)'); process.exit(2); }
    for (const n of picks) {
      const row = data.rows[n - 1];
      const id = row && (row.doi ? parseId(row.doi) : row.arxiv ? parseId(row.arxiv) : null);
      if (!id) out.push(`FAIL  row ${n}: no DOI or arXiv id (add it by hand from the landing page)`);
      else queue.push({ id });
    }
  }
  if (flag('inbox')) {
    const files = fs.existsSync(P.inbox) ? fs.readdirSync(P.inbox).filter((f) => /\.pdf$/i.test(f)) : [];
    if (!files.length) out.push(`inbox empty (${P.inbox})`);
    if (files.length && !python()) { console.error('lit-fetch: --inbox needs Python + pymupdf (node .agents/scripts/tools-check.mjs --for read)'); process.exit(2); }
    for (const f of files) {
      const full = path.join(P.inbox, f);
      const pr = probe(full);
      const id = pr && (pr.dois.length ? parseId(pr.dois[0]) : pr.arxiv ? parseId(pr.arxiv) : null);
      if (!id) out.push(`ASK   ${f}: no DOI found inside. Ask the user for the DOI, then: lit-fetch.mjs <doi> --file "${full}"`);
      else queue.push({ id, file: full });
    }
  }

  for (const q of queue) {
    const r = await addItem(q.id, lib, bib, { file: q.file, noPdf });
    out.push(r.line);
    saveLib(lib);
    await sleep(400);
  }
  saveLib(lib);
  console.log(out.join('\n'));
  const counts = Object.values(lib).reduce((a, e) => ({ ...a, [e.status]: (a[e.status] || 0) + 1 }), {});
  console.log(`\nlibrary: ${Object.entries(counts).map(([k, v]) => `${k} ${v}`).join(', ')} -> ${P.libMd}, ${P.bib}${counts['to-download'] ? `, ${P.todo}` : ''}`);
  if (counts['pdf-check']) console.log('pdf-check: open those PDFs and confirm title/authors before reading them.');
  if (!EMAIL) console.log('tip: set RESEARCH_EMAIL (ask the user) so Unpaywall can find more legal free copies.');
}

main().catch((e) => { console.error(`lit-fetch: ${e.message}`); process.exit(1); });
