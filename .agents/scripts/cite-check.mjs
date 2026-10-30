#!/usr/bin/env node
// Workflow Kit - check the citations of a manuscript BEFORE building or handing it in. Catches the mistakes AI makes
// most: citing a paper that is not in the bibliography, citing a paper nobody read, and "quotes" that are not in the
// source. Run it after every writing session (wf-research Phase 9) and before doc-build.
//
// Usage: node .agents/scripts/cite-check.mjs <manuscript.md> [--bib FILE] [--notes DIR] [--text DIR] [--allow-partial]
//   --bib     default: the front matter "bibliography:" of the manuscript, else research/refs.bib
//   --notes   note cards, one per source: <notes>/<key>.md (default research/notes)
//   --text    read-doc.py output, one folder per source: <text>/<key>/text.md (default research/text)
//   --allow-partial   read-partial note cards are a warning instead of an error
//
// Errors (exit 1):
//   E1 cited key is not in the .bib                  -> fix the key, or add the source with lit-fetch.mjs
//   E2 cited key has no note card                    -> read the source first (wf-research Phase 6), then cite
//   E3 note card status is abstract-only / missing   -> only read-full sources can carry claims (read-partial: see flag)
//   E4 a quote in a note card is not in the source text (verbatim, whitespace ignored) -> copy it again from text.md
//   E5 a direct quote in the manuscript ("..." [@key, p. N]) is not in that source's text
//   E6 duplicate key in the .bib
// Warnings: bib entry without DOI/URL, bib entries never cited, quote found only with different case, quote not on the
// pdf page the note says, read-partial sources.

import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const opt = (n) => { const i = argv.indexOf(`--${n}`); return i >= 0 ? argv[i + 1] : undefined; };
const VALUED = ['bib', 'notes', 'text'];
const mdFile = argv.find((a, i) => !a.startsWith('--') && !(i > 0 && VALUED.includes(argv[i - 1].slice(2))));
if (!mdFile || !fs.existsSync(mdFile)) {
  console.error('usage: cite-check.mjs <manuscript.md> [--bib FILE] [--notes DIR] [--text DIR] [--allow-partial]');
  process.exit(2);
}

const src = fs.readFileSync(mdFile, 'utf8');
const fmMatch = src.match(/^---\r?\n([\s\S]*?)\r?\n---/);
const fmBib = fmMatch && (fmMatch[1].match(/^bibliography:\s*["']?([^"'\r\n]+)["']?\s*$/m) || [])[1];
const bibPath = opt('bib') || (fmBib ? path.resolve(path.dirname(mdFile), fmBib.trim()) : path.join('research', 'refs.bib'));
const notesDir = opt('notes') || path.join('research', 'notes');
const textDir = opt('text') || path.join('research', 'text');
const allowPartial = argv.includes('--allow-partial');

const errors = [], warns = [];
const err = (code, msg) => errors.push(`${code} ${msg}`);
const warn = (msg) => warns.push(msg);

// ---------- bibliography ----------
if (!fs.existsSync(bibPath)) {
  console.error(`cite-check: bibliography not found: ${bibPath}`);
  process.exit(2);
}
const bib = new Map();
for (const chunk of fs.readFileSync(bibPath, 'utf8').split(/\n(?=\s*@)/)) {
  const k = chunk.match(/@(\w+)\s*\{\s*([^,\s]+)\s*,/);
  if (!k || /^(comment|preamble|string)$/i.test(k[1])) continue;
  if (bib.has(k[2])) err('E6', `duplicate key in ${bibPath}: ${k[2]}`);
  bib.set(k[2], { doi: /\bdoi\s*=/i.test(chunk), url: /\burl\s*=/i.test(chunk) });
}

// ---------- citations in the manuscript ----------
const body = src.replace(/^---\r?\n[\s\S]*?\r?\n---/, '')
  .replace(/```[\s\S]*?```/g, '').replace(/`[^`\n]*`/g, '').replace(/<!--[\s\S]*?-->/g, '');
const cited = new Map(); // key -> count
for (const m of body.matchAll(/(^|[^\w.@])-?@([A-Za-z0-9_][\w:.#$%&+?<>~/-]*)/g)) {
  const key = m[2].replace(/[.:,;]+$/, '');
  if (/^(fig|tbl|sec|eq):/.test(key)) continue; // pandoc-crossref labels
  cited.set(key, (cited.get(key) || 0) + 1);
}

// ---------- note cards ----------
function readNote(key) {
  const f = path.join(notesDir, `${key}.md`);
  if (!fs.existsSync(f)) return null;
  const t = fs.readFileSync(f, 'utf8');
  const fm = (t.match(/^---\r?\n([\s\S]*?)\r?\n---/) || [])[1] || '';
  const get = (k) => (fm.match(new RegExp(`^${k}:\\s*(.+)$`, 'm')) || [])[1]?.trim().replace(/^["']|["']$/g, '');
  return { file: f, text: t, status: get('status'), pagesRead: get('pages_read') };
}

// ---------- source text (read-doc output) ----------
const norm = (s) => s.normalize('NFKC').replace(/<\/?sup>/g, '').replace(/­/g, '')
  .replace(/[‘’‚′]/g, "'").replace(/[“”„″]/g, '"').replace(/[‐-―]/g, '-')
  .replace(/\s+/g, ' ').trim();
const textCache = new Map();
function sourceText(key) {
  if (textCache.has(key)) return textCache.get(key);
  const f = path.join(textDir, key, 'text.md');
  let v = null;
  if (fs.existsSync(f)) {
    const raw = fs.readFileSync(f, 'utf8');
    const pages = new Map();
    const parts = raw.split(/<!-- (?:page|slide) (\d+)[^>]*-->/);
    for (let i = 1; i < parts.length; i += 2) pages.set(+parts[i], norm(parts[i + 1]));
    v = { all: norm(raw), pages };
  }
  textCache.set(key, v);
  return v;
}
function findQuote(key, quote, pdfPage) {
  const st = sourceText(key);
  if (!st) return { state: 'no-text' };
  const q = norm(quote);
  if (st.all.includes(q)) {
    if (pdfPage && st.pages.size && ![pdfPage - 1, pdfPage, pdfPage + 1].some((p) => st.pages.get(p)?.includes(q))) return { state: 'other-page' };
    return { state: 'ok' };
  }
  if (st.all.toLowerCase().includes(q.toLowerCase())) return { state: 'case' };
  return { state: 'missing' };
}

// ---------- checks ----------
for (const [key, n] of cited) {
  if (!bib.has(key)) { err('E1', `[@${key}] (${n}x) is not in ${bibPath}`); continue; }
  const note = readNote(key);
  if (!note) { err('E2', `[@${key}] has no note card ${path.join(notesDir, `${key}.md`)}: read the source before citing it`); continue; }
  if (note.status === 'read-partial') {
    (allowPartial ? warn : (m) => err('E3', m))(`[@${key}] note status read-partial (pages read: ${note.pagesRead || '?'}): cite only what is on those pages`);
  } else if (note.status !== 'read-full') {
    err('E3', `[@${key}] note status is "${note.status || 'missing'}" (need read-full): an abstract is not enough to cite`);
  }
  // Quotes in the note card: > "exact text" (p. 12; pdf 3)
  for (const m of note.text.matchAll(/^>\s*"(.+)"\s*\(([^)]*)\)\s*$/gm)) {
    const pdf = parseInt((m[2].match(/pdf\s*(\d+)/i) || [])[1], 10) || null;
    const r = findQuote(key, m[1], pdf);
    if (r.state === 'missing') err('E4', `${note.file}: quote not found in ${textDir}/${key}/text.md: "${m[1].slice(0, 70)}..."`);
    if (r.state === 'case') warn(`${note.file}: quote found only with different upper/lower case: "${m[1].slice(0, 50)}..."`);
    if (r.state === 'other-page') warn(`${note.file}: quote is in the source but not on pdf page ${pdf} (+-1): fix the page number`);
    if (r.state === 'no-text') { warn(`${key}: no ${textDir}/${key}/text.md, note-card quotes not checked (run read-doc.py)`); break; }
  }
}

// Direct quotes in the manuscript: "..." [@key, p. N] (at least 6 words)
for (const m of body.matchAll(/["“]([^"”]{25,}?)["”]\s*\[([^\]]*@[^\]]*)\]/g)) {
  if (m[1].trim().split(/\s+/).length < 6) continue;
  const keys = [...m[2].matchAll(/@([\w:.#$%&+?<>~/-]+)/g)].map((k) => k[1].replace(/[.:,;]+$/, '')).filter((k) => bib.has(k));
  const results = keys.map((k) => findQuote(k, m[1]));
  if (keys.length && results.every((r) => r.state === 'missing')) err('E5', `quote not found in ${keys.join(', ')}: "${m[1].slice(0, 70)}..."`);
}

for (const [key, e] of bib) {
  if (!e.doi && !e.url) warn(`bib ${key}: no doi or url (readers cannot find it; add one if it exists)`);
  if (!cited.has(key)) warn(`bib ${key}: never cited in ${path.basename(mdFile)} (fine if the .bib is shared; APA lists only cited works)`);
}

console.log(`cite-check: ${path.basename(mdFile)} cites ${cited.size} source(s), ${[...cited.values()].reduce((a, b) => a + b, 0)} citation(s); bib ${bib.size} entries (${bibPath})`);
for (const e of errors) console.log(`  ERROR ${e}`);
for (const w of warns) console.log(`  warn  ${w}`);
console.log(errors.length ? `\n${errors.length} error(s). Fix them before building the document.` : '\nNo errors.');
process.exit(errors.length ? 1 : 0);
