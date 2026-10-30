#!/usr/bin/env node
// Workflow Kit - prose check for Markdown documents (reports, proposals, articles, slides).
// Catches the habits that make AI-written documents feel cheap: bullet-point walls, stock phrases,
// bold everywhere, em dashes, emoji, placeholders. Rules: .agents/knowledge/writing.md
//
// Usage: node .agents/scripts/doc-check.mjs <file.md> [--slides] [--strict] [--lang id|en]
//   --slides  slide deck rules (automatic for front matter `docstyle: slides`)
//   --strict  warnings fail too (exit 1)
//   --lang    default: front matter `lang`, else id
// Exit: 0 = no errors, 1 = errors (or warnings with --strict), 2 = bad usage.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const STOCK = {
  id: [
    'era digital', 'di era modern', 'di zaman sekarang', 'di era globalisasi',
    'tidak dapat dipungkiri', 'tak dapat dipungkiri', 'tidak bisa dipungkiri',
    'memainkan peran penting', 'memainkan peranan penting', 'memegang peranan penting', 'peran yang sangat penting',
    'lanskap', 'menavigasi', 'holistik', 'sinergi', 'mari kita', 'menyelami',
    'perlu dicatat bahwa', 'penting untuk dicatat', 'penting untuk diingat', 'perlu diingat bahwa',
    'dalam dunia yang terus berkembang', 'seiring perkembangan zaman', 'seiring dengan perkembangan zaman',
    'revolusioner', 'solusi inovatif', 'membuka pintu', 'membuka jalan bagi', 'lebih dari sekadar',
    'garda terdepan', 'kunci utama', 'tak terpisahkan', 'pada intinya', 'secara keseluruhan,', 'kesimpulannya,',
  ],
  en: [
    'delve', 'tapestry', 'testament to', 'crucial', 'pivotal', 'seamless', 'leverage', 'in today\'s fast-paced',
    'in today\'s digital', 'ever-evolving', 'ever-changing', 'landscape', 'navigate the', 'realm', 'embark',
    'unlock the', 'unleash', 'game-changer', 'game changer', 'cutting-edge', 'it\'s important to note',
    'it is important to note', 'it\'s worth noting', 'in conclusion', 'furthermore,', 'moreover,',
    'additionally,', 'holistic', 'synergy', 'elevate', 'empower', 'foster', 'underscore', 'showcase',
    'a myriad of', 'plethora',
  ],
};

// Common non-standard spellings (KBBI/PUEBI). Only checked for Indonesian.
const SPELLING = {
  analisa: 'analisis', resiko: 'risiko', obyek: 'objek', subyek: 'subjek', sistim: 'sistem', praktek: 'praktik',
  kwalitas: 'kualitas', aktifitas: 'aktivitas', efektifitas: 'efektivitas', kreatifitas: 'kreativitas',
  produktifitas: 'produktivitas', nasehat: 'nasihat', jaman: 'zaman', ijin: 'izin', silahkan: 'silakan',
  antri: 'antre', apotik: 'apotek', hutang: 'utang', merubah: 'mengubah', dirubah: 'diubah', perduli: 'peduli',
  standarisasi: 'standardisasi', terlanjur: 'telanjur', sekedar: 'sekadar', ketrampilan: 'keterampilan',
  trampil: 'terampil', tehnik: 'teknik', tehnologi: 'teknologi', fikir: 'pikir', difikirkan: 'dipikirkan',
};

const LIST_OK = /referensi|daftar pustaka|pustaka|references|bibliography|lampiran|appendix|checklist|rekomendasi|saran|recommendation/i;

function stripInline(s) {
  return s.replace(/`[^`]*`/g, '').replace(/\]\([^)]*\)/g, ']').replace(/<[^>]+>/g, '');
}

function words(s) {
  return stripInline(s).split(/\s+/).filter((w) => /[\p{L}\p{N}]/u.test(w)).length;
}

export function frontMatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n(---|\.\.\.)\r?\n/);
  const fm = {};
  if (!m) return { fm, body: text, offset: 0 };
  for (const line of m[1].split(/\r?\n/)) {
    const kv = line.match(/^([A-Za-z][\w-]*):\s*(.*)$/);
    if (kv) fm[kv[1]] = kv[2].replace(/^["']|["']$/g, '').trim();
  }
  return { fm, body: text.slice(m[0].length), offset: m[0].split(/\r?\n/).length - 1 };
}

// Split the body into blocks: heading, list, para, table, quote, code, other. Line numbers are 1-based.
function blocks(body, offset) {
  const out = [];
  const lines = body.split(/\r?\n/);
  let cur = null;
  let fence = null;
  let comment = false;
  const flush = () => { if (cur) out.push(cur); cur = null; };
  lines.forEach((raw, i) => {
    const n = i + 1 + offset;
    const line = raw.replace(/\s+$/, '');
    if (comment) { if (line.includes('-->')) comment = false; return; }
    if (fence) { if (line.trim().startsWith(fence)) fence = null; return; }
    const f = line.trim().match(/^(```|~~~)/);
    if (f) { flush(); fence = f[1]; return; }
    if (line.trim().startsWith('<!--')) { flush(); if (!line.includes('-->')) comment = true; return; }
    if (line.trim() === '') { flush(); return; }
    if (/^:::/.test(line.trim())) { flush(); return; }
    let type = 'para';
    if (/^#{1,6}\s/.test(line)) type = 'heading';
    else if (/^\s*([-*+]|\d+[.)])\s+/.test(line)) type = 'list';
    else if (/^\s*\|/.test(line) || /^:\s/.test(line)) type = 'table';
    else if (/^>/.test(line)) type = 'quote';
    else if (/^\s*(---+|\*\*\*+)\s*$/.test(line)) type = 'other';
    if (type === 'heading') { flush(); out.push({ type, lines: [{ n, text: line }] }); return; }
    if (cur && (cur.type === type || (cur.type === 'list' && /^\s+\S/.test(line)) || (cur.type === 'para' && type === 'para'))) {
      cur.lines.push({ n, text: line });
      return;
    }
    flush();
    cur = { type, lines: [{ n, text: line }] };
  });
  flush();
  return out;
}

export function checkMarkdown(text, opts = {}) {
  const { fm, body, offset } = frontMatter(text);
  const lang = (opts.lang || fm.lang || 'id').slice(0, 2).toLowerCase();
  const slides = Boolean(opts.slides) || fm.docstyle === 'slides';
  const issues = [];
  const add = (level, n, msg) => issues.push({ level, line: n, msg });
  const bs = blocks(body, offset);

  // Line-level checks on prose (not code/comments).
  const stock = [...STOCK[lang === 'en' ? 'en' : 'id'], ...(lang === 'en' ? [] : STOCK.en.filter((p) => !p.includes(',')))];
  let dashes = 0;
  let totalWords = 0;
  for (const b of bs) {
    for (const { n, text: t } of b.lines) {
      const s = stripInline(t);
      const lower = s.toLowerCase();
      for (const ch of s.matchAll(/\p{Extended_Pictographic}/gu)) {
        if (!/[©®™]/.test(ch[0])) { add('error', n, `emoji "${ch[0]}" - no emoji in documents`); break; }
      }
      if (/lorem ipsum|\bTODO\b|\bTBD\b|\bFIXME\b|\?\?\?|\[(isi|tambahkan|masukkan|perlu|insert|placeholder|citation needed)[^\]]*\]|<(isi|nama|tanggal|judul)[^>]*>/i.test(s)) {
        add('error', n, 'placeholder left in the text');
      }
      const hits = stock.filter((p) => new RegExp(`(^|[^\\p{L}])${p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'iu').test(lower));
      for (const p of hits.filter((h) => !hits.some((o) => o !== h && o.includes(h)))) {
        add('warn', n, `stock phrase "${p}" - say the concrete thing instead`);
      }
      if (/\bnot only\b.*\bbut also\b|\bbukan hanya\b.*\btetapi juga\b|\btidak hanya\b.*\btetapi juga\b/i.test(s) && b.type !== 'heading') {
        add('info', n, '"tidak hanya ... tetapi juga" - fine once, a tic if repeated');
      }
      if (lang === 'id') {
        for (const w of lower.match(/\p{L}+/gu) || []) {
          if (SPELLING[w]) add('warn', n, `ejaan: "${w}" -> "${SPELLING[w]}" (KBBI)`);
        }
        if (/\bdi mana\b/i.test(s) && !/\?/.test(s)) add('info', n, '"di mana" as a connector - usually "yang" or "tempat" reads better');
      }
      if (b.type !== 'heading' && b.type !== 'table') {
        dashes += (s.match(/—|(?<!-)---(?!-)/g) || []).length;
        totalWords += words(s);
      }
    }
  }
  if (dashes > Math.max(2, totalWords / 400)) {
    add('warn', 0, `${dashes} em dashes in ${totalWords} words - a strong AI tell; use commas, colons, or two sentences`);
  }

  // Block-level checks.
  let listItems = 0;
  let paras = 0;
  let boldLabelBullets = 0;
  let shortRun = 0;
  const openers = new Map();
  let section = null; // { title, n, hasPara, hasList }
  const closeSection = () => {
    if (!slides && section && section.hasList && !section.hasPara && !LIST_OK.test(section.title)) {
      add('warn', section.n, `section "${section.title}" is only a list - introduce or explain it in a paragraph`);
    }
  };
  for (const b of bs) {
    const first = b.lines[0];
    if (b.type === 'heading') {
      closeSection();
      const level = first.text.match(/^#+/)[0].length;
      const title = first.text.replace(/^#+\s*/, '').replace(/\s*\{[^}]*\}\s*$/, '');
      section = { title, n: first.n, hasPara: false, hasList: false, bullets: 0, words: 0 };
      if (!slides && level >= 4) add('warn', first.n, `heading level ${level} - more than 3 levels makes a document hard to follow`);
      if (/[!?]$/.test(title) && !slides) add('info', first.n, 'heading ends with ! or ? - plain statements read better in reports');
      shortRun = 0;
      continue;
    }
    if (b.type === 'list') {
      const items = b.lines.filter((l) => /^\s*([-*+]|\d+[.)])\s+/.test(l.text));
      listItems += items.length;
      if (section) { section.hasList = true; section.bullets += items.length; }
      // Group continuation lines into their item to measure length.
      let curItem = null;
      const measured = [];
      for (const l of b.lines) {
        if (/^\s*([-*+]|\d+[.)])\s+/.test(l.text)) { curItem = { n: l.n, text: l.text }; measured.push(curItem); } else if (curItem) curItem.text += ` ${l.text}`;
        const indent = l.text.match(/^\s*/)[0].length;
        if (/^\s*([-*+]|\d+[.)])\s+/.test(l.text) && indent >= 8) add('warn', l.n, 'list nested 3 levels deep - flatten it or use a table');
      }
      for (const it of measured) {
        const w = words(it.text.replace(/^\s*([-*+]|\d+[.)])\s+/, ''));
        if (slides && w > 15) add('warn', it.n, `slide bullet has ${w} words - keep bullets under ~12 words`);
        if (!slides && w > 40) add('warn', it.n, `list item has ${w} words - this is a paragraph, write it as one`);
        if (/^\s*([-*+]|\d+[.)])\s+\*\*[^*]+(:\*\*|\*\*\s*[:\-–—])/.test(it.text)) boldLabelBullets += 1;
      }
      shortRun = 0;
      continue;
    }
    if (b.type !== 'para') { shortRun = 0; continue; }
    paras += 1;
    if (section) section.hasPara = true;
    const textAll = b.lines.map((l) => l.text).join(' ');
    const w = words(textAll);
    if (section) section.words += w;
    if (!slides && w > 200) add('warn', first.n, `paragraph has ${w} words - split it where the idea turns`);
    if (slides && w > 40) add('warn', first.n, `${w} words of running text on a slide - move detail to speaker notes`);
    const bolds = (textAll.match(/\*\*[^*]+\*\*|__[^_]+__/g) || []).length;
    if (bolds > 2) add('warn', first.n, `${bolds} bold phrases in one paragraph - bold at most one key term`);
    if ((textAll.match(/!/g) || []).length > 1 && !slides) add('info', first.n, 'several exclamation marks - formal documents rarely need them');
    shortRun = w <= 14 ? shortRun + 1 : 0;
    if (!slides && shortRun === 4) add('warn', first.n, '4 very short paragraphs in a row - choppy; merge related sentences');
    const opener = stripInline(textAll).toLowerCase().split(/\s+/).slice(0, 2).join(' ').replace(/[^\p{L}\s]/gu, '');
    if (opener) openers.set(opener, [...(openers.get(opener) || []), first.n]);
  }
  closeSection();

  if (slides) {
    // Per-slide density: count bullets under each heading.
    let cur = null;
    for (const b of bs) {
      if (b.type === 'heading') { cur = { n: b.lines[0].n, bullets: 0 }; continue; }
      if (cur && b.type === 'list') {
        cur.bullets += b.lines.filter((l) => /^\s*([-*+]|\d+[.)])\s+/.test(l.text)).length;
        if (cur.bullets > 6 && !cur.flagged) { add('warn', cur.n, `slide has ${cur.bullets} bullets - max ~6; split the slide`); cur.flagged = true; }
      }
    }
  } else {
    const share = listItems + paras ? listItems / (listItems + paras) : 0;
    if (listItems >= 6 && share > 0.5) {
      add('warn', 0, `${Math.round(share * 100)}% of blocks are list items - explain in paragraphs; keep lists for steps, options, and items that really are a list`);
    }
    if (boldLabelBullets >= 4) {
      add('warn', 0, `${boldLabelBullets} "**Label:** text" bullets - a typical AI pattern; use paragraphs or a table`);
    }
    for (const [op, ns] of openers) {
      if (ns.length >= 3 && op.split(' ').length === 2) add('warn', ns[0], `${ns.length} paragraphs start with "${op}" (lines ${ns.join(', ')}) - vary the openings`);
    }
  }
  const stats = { words: totalWords, listItems, paragraphs: paras, lang, slides };
  return { issues, stats };
}

function main() {
  const args = process.argv.slice(2);
  const file = args.find((a) => !a.startsWith('--'));
  if (!file) {
    console.error('usage: node .agents/scripts/doc-check.mjs <file.md> [--slides] [--strict] [--lang id|en]');
    process.exit(2);
  }
  const langArg = args.includes('--lang') ? args[args.indexOf('--lang') + 1] : undefined;
  const text = fs.readFileSync(file, 'utf8');
  const { issues, stats } = checkMarkdown(text, { slides: args.includes('--slides'), lang: langArg });
  const strict = args.includes('--strict');
  console.log(`doc-check: ${file}`);
  for (const i of issues.sort((a, b) => a.line - b.line)) {
    console.log(`  ${i.line ? String(i.line).padStart(4) : '   -'}: [${i.level}] ${i.msg}`);
  }
  const errors = issues.filter((i) => i.level === 'error').length;
  const warns = issues.filter((i) => i.level === 'warn').length;
  console.log(`  ${errors} error(s), ${warns} warning(s) - ${stats.words} words, ${stats.paragraphs} paragraphs, ${stats.listItems} list items`);
  process.exit(errors || (strict && warns) ? 1 : 0);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
