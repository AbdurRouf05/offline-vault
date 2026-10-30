#!/usr/bin/env node
// Workflow Kit - build documents from Markdown with tested templates.
// Markdown is the source; styling comes from .agents/templates/documents/ (never style per document).
//   PDF  : Pandoc -> Typst (default) or Pandoc -> XeLaTeX (--engine latex)
//   DOCX : Pandoc + reference.docx / reference-akademik.docx
//   PPTX : Pandoc + reference.pptx (front matter `docstyle: slides`)
// Citations (front matter `bibliography: refs.bib`): citeproc + bundled CSL (`csl: apa` default, or ieee,
//   harvard-cite-them-right, chicago-author-date, ...; see templates/documents/csl/), citations link to the
//   reference list, and in DOCX each citation is a Mendeley-style field (citation-fields.lua).
// Guide: .agents/knowledge/documents.md
//
// Usage: node .agents/scripts/doc-build.mjs <file.md> [options]
//   --to pdf|docx|pptx|all  default: pdf (pptx for docstyle: slides); all = pdf+docx (slides: pptx+pdf)
//   --style laporan|akademik|slides   overrides front matter `docstyle` (default laporan)
//   --engine typst|latex    PDF engine (default typst)
//   --out <dir>             output folder (default: next to the .md)
//   --name <base>           output file name without extension (default: the .md name)
//   --toc                   add a table of contents
//   --ref <file.docx|pptx>  take DOCX/PPTX styles from this file instead of the kit's (e.g. a campus template)
//   --preview               render every page to PNG so you can look at it
//   --keep-typ              keep the intermediate .typ file (debugging)
//   --no-check              skip the prose check (doc-check.mjs)
// Exit: 0 ok, 1 build failed, 2 bad usage, 3 built but doc-check found errors.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { checkMarkdown, frontMatter } from './doc-check.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(SCRIPT_DIR, '..', '..');
const TPL = path.resolve(SCRIPT_DIR, '..', 'templates', 'documents');
const IS_WIN = process.platform === 'win32';
const STYLES = ['laporan', 'akademik', 'slides'];

const LATEX_VARS = {
  laporan: { mainfont: 'Cambria', fontsize: '11pt', geometry: 'a4paper,margin=2.5cm', linestretch: '1.2' },
  akademik: {
    mainfont: 'Times New Roman', fontsize: '12pt', geometry: 'a4paper,left=4cm,top=4cm,right=3cm,bottom=3cm',
    linestretch: '1.5', indent: 'true',
  },
};

function die(msg, code = 1) {
  console.error(`doc-build: ${msg}`);
  process.exit(code);
}

function parseArgs(argv) {
  const o = { to: null, style: null, engine: 'typst', out: null, name: null, toc: false, preview: false, keepTyp: false, check: true, ref: null };
  const rest = [];
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    const val = () => { if (i + 1 >= argv.length) die(`${a} needs a value`, 2); i += 1; return argv[i]; };
    if (a === '--to') o.to = val();
    else if (a === '--style') o.style = val();
    else if (a === '--engine') o.engine = val();
    else if (a === '--out') o.out = val();
    else if (a === '--name') o.name = val();
    else if (a === '--toc') o.toc = true;
    else if (a === '--ref') o.ref = path.resolve(val());
    else if (a === '--preview') o.preview = true;
    else if (a === '--keep-typ') o.keepTyp = true;
    else if (a === '--no-check') o.check = false;
    else if (a.startsWith('--')) die(`unknown option ${a}`, 2);
    else rest.push(a);
  }
  if (rest.length !== 1) die('usage: node .agents/scripts/doc-build.mjs <file.md> [--to pdf|docx|pptx|all] [--style laporan|akademik|slides] [--preview]', 2);
  o.input = path.resolve(rest[0]);
  if (o.ref && !fs.existsSync(o.ref)) die(`--ref file not found: ${o.ref}`, 2);
  return o;
}

// Find an executable on PATH or in the usual install folders. Returns the command or null.
const toolCache = new Map();
function findTool(name, extra = []) {
  if (toolCache.has(name)) return toolCache.get(name);
  const local = process.env.LOCALAPPDATA || '';
  const pf = process.env.ProgramFiles || 'C:\\Program Files';
  const known = {
    pandoc: [path.join(local, 'Pandoc', 'pandoc.exe'), path.join(pf, 'Pandoc', 'pandoc.exe')],
    typst: [path.join(local, 'Microsoft', 'WinGet', 'Links', 'typst.exe'), path.join(os.homedir(), '.cargo', 'bin', IS_WIN ? 'typst.exe' : 'typst')],
    soffice: [path.join(pf, 'LibreOffice', 'program', 'soffice.exe'), '/Applications/LibreOffice.app/Contents/MacOS/soffice'],
    pdftoppm: [],
  };
  let found = null;
  for (const cand of [name, ...(known[name] || []), ...extra]) {
    if (cand !== name && !fs.existsSync(cand)) continue;
    const r = spawnSync(cand, [name === 'soffice' ? '--version' : name === 'pdftoppm' ? '-v' : '--version'], { encoding: 'utf8', timeout: 20000 });
    if (!r.error) { found = cand; break; }
  }
  toolCache.set(name, found);
  return found;
}

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 300000, ...opts });
  if (r.error) return { ok: false, out: String(r.error.message) };
  return { ok: r.status === 0, out: `${r.stdout || ''}${r.stderr || ''}`.trim() };
}

function needTool(name) {
  const t = findTool(name);
  if (t) return t;
  const hint = {
    pandoc: 'Windows: winget install JohnMacFarlane.Pandoc | macOS: brew install pandoc | Linux: sudo apt install pandoc',
    typst: 'Windows: winget install Typst.Typst | macOS: brew install typst | Linux: snap install typst, or cargo install typst-cli',
  }[name] || '';
  die(`${name} not found. Install it, then run again.\n  ${hint}\n  Ask the user before installing anything.`);
  return null;
}

function commonAncestor(a, b) {
  const pa = path.resolve(a).split(path.sep);
  const pb = path.resolve(b).split(path.sep);
  if (pa[0].toLowerCase() !== pb[0].toLowerCase()) return null;
  const out = [];
  for (let i = 0; i < Math.min(pa.length, pb.length); i += 1) {
    if ((IS_WIN ? pa[i].toLowerCase() : pa[i]) !== (IS_WIN ? pb[i].toLowerCase() : pb[i])) break;
    out.push(pa[i]);
  }
  return out.length === 1 ? `${out[0]}${path.sep}` : out.join(path.sep);
}

function pageCount(pdf) {
  const info = findTool('pdfinfo');
  if (info) {
    const r = run(info, [pdf]);
    const m = r.out.match(/Pages:\s+(\d+)/);
    if (m) return Number(m[1]);
  }
  const raw = fs.readFileSync(pdf).toString('latin1');
  const n = (raw.match(/\/Type\s*\/Page(?![s\w])/g) || []).length;
  return n || null;
}

// Pre-flight checks for things that break rendering (not prose).
function formatChecks(body, mdDir, style, fm = {}) {
  const warns = [];
  const bib = fm.bibliography;
  if (bib && !/^\[/.test(bib) && !/^[a-z]+:/i.test(bib) && !fs.existsSync(path.resolve(mdDir, bib))) warns.push(`front matter bibliography: file not found: ${bib}`);
  if (fm.csl && !resolveCsl(fm.csl, mdDir) && !/^[a-z]+:/i.test(fm.csl) && !fs.existsSync(path.resolve(mdDir, fm.csl))) {
    warns.push(`front matter csl: "${fm.csl}" is neither a file nor a bundled style (${bundledStyles().join(', ')})`);
  }
  if (!fm.bibliography && /\[[^\]\n]*@[A-Za-z][\w:.-]*/.test(body.replace(/`[^`]*`/g, ''))) {
    warns.push('citations like [@key] found but no `bibliography:` in front matter - they will print as raw text');
  }
  const lines = body.split(/\r?\n/);
  let fence = false;
  lines.forEach((line, i) => {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    if (fence) return;
    if (style !== 'slides' && /^\s*\|.*\|\s*$/.test(line) && line.length > 72) {
      warns.push(`line ${i + 1}: pipe table row is ${line.length} chars - over 72, Pandoc sizes columns from the dashes; keep rows <= 72 chars or set the dash counts on purpose`);
    }
    for (const m of line.matchAll(/!\[[^\]]*\]\(([^)\s]+)/g)) {
      const src = decodeURI(m[1]);
      if (!/^[a-z]+:/i.test(src) && !fs.existsSync(path.resolve(mdDir, src))) warns.push(`line ${i + 1}: image not found: ${src}`);
    }
    if (style === 'slides' && /\^\[/.test(line)) warns.push(`line ${i + 1}: footnote in slides - Pandoc moves it to an extra "Notes" slide; put it in ::: notes instead`);
  });
  return warns;
}

// Options shared by every pandoc call: default language, table of contents, heading numbers, citations.
// toc/numbersections in front matter are template variables for PDF only, so pass them as options too (DOCX).
function commonArgs(args, o, ctx, doc = true) {
  const yes = (v) => /^(true|yes)$/i.test(v || '');
  if (!ctx.fm.lang) args.push('-M', 'lang=id');
  if (doc && (o.toc || yes(ctx.fm.toc))) {
    args.push('--toc');
    // Pandoc's DOCX writer always says "Table of Contents" unless toc-title is set.
    if (!ctx.fm['toc-title'] && /^id/i.test(ctx.fm.lang || 'id')) args.push('-M', 'toc-title=Daftar Isi');
  }
  if (doc && yes(ctx.fm.numbersections)) args.push('--number-sections');
  if (ctx.fm.bibliography) {
    args.push('--citeproc');
    const csl = resolveCsl(ctx.fm.csl, ctx.mdDir);
    if (csl) args.push(`--csl=${csl}`);
    // Citations link to their reference-list entry (Ctrl+click in Word, click in PDF).
    if (ctx.fm['link-citations'] === undefined) args.push('-M', 'link-citations=true');
  }
}

// Citation style: no `csl:` -> the bundled APA 7; a bare name like `ieee` -> templates/documents/csl/ieee.csl;
// a path that exists next to the document -> left to Pandoc (returns null).
function resolveCsl(value, mdDir) {
  if (!value) return path.join(TPL, 'csl', 'apa.csl');
  if (/^[a-z]+:/i.test(value) || fs.existsSync(path.resolve(mdDir, value))) return null;
  const bundled = path.join(TPL, 'csl', `${value.replace(/\.csl$/i, '')}.csl`);
  return fs.existsSync(bundled) ? bundled : null;
}

function bundledStyles() {
  const dir = path.join(TPL, 'csl');
  return fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith('.csl')).map((f) => f.slice(0, -4)) : [];
}

function buildTypstPdf(o, ctx, outPdf) {
  const pandoc = needTool('pandoc');
  const typst = needTool('typst');
  let root = commonAncestor(PROJECT_ROOT, ctx.mdDir);
  let tplDir = path.join(TPL, 'typst');
  let copied = null;
  if (!root) {
    // Different drives: copy the templates next to the document for this build.
    copied = path.join(ctx.mdDir, '.doc-build-typst');
    fs.cpSync(tplDir, copied, { recursive: true });
    tplDir = copied;
    root = ctx.mdDir;
  }
  const tplRel = `/${path.relative(root, path.join(tplDir, `${ctx.style}.typ`)).split(path.sep).join('/')}`;
  const typFile = path.join(ctx.mdDir, `${o.name}.build.typ`);
  const args = [ctx.inputName, '-t', 'typst', '-s', '-V', `template=${tplRel}`, '-o', typFile];
  commonArgs(args, o, ctx);
  try {
    const p = run(pandoc, args, { cwd: ctx.mdDir });
    if (!p.ok) die(`pandoc failed:\n${p.out}`);
    if (p.out) ctx.notes.push(...p.out.split(/\r?\n/).map((l) => `pandoc: ${l}`));
    const t = run(typst, ['compile', '--root', root, typFile, outPdf]);
    if (!t.ok) die(`typst failed (rerun with --keep-typ to inspect ${path.basename(typFile)}):\n${t.out}`);
    if (t.out) ctx.notes.push(...t.out.split(/\r?\n/).filter((l) => /warning|error|unknown font/i.test(l)).map((l) => `typst: ${l.trim()}`));
    if (o.preview) {
      const dir = previewDir(o, 'pdf');
      const r = run(typst, ['compile', '--root', root, '--format', 'png', '--ppi', '60', typFile, path.join(dir, 'page-{0p}.png')]);
      ctx.previews.pdf = r.ok ? listPngs(dir) : null;
    }
  } finally {
    if (!o.keepTyp && fs.existsSync(typFile)) fs.rmSync(typFile);
    if (copied) fs.rmSync(copied, { recursive: true, force: true });
  }
}

function buildLatexPdf(o, ctx, outPdf) {
  const pandoc = needTool('pandoc');
  const style = ctx.style === 'akademik' ? 'akademik' : 'laporan';
  const args = [ctx.inputName, '-o', outPdf, '--pdf-engine=xelatex'];
  for (const [k, v] of Object.entries(LATEX_VARS[style])) if (ctx.fm[k] === undefined) args.push('-V', `${k}=${v}`);
  commonArgs(args, o, ctx);
  const p = run(pandoc, args, { cwd: ctx.mdDir, timeout: 900000 });
  if (!p.ok) die(`pandoc/xelatex failed (is a LaTeX distribution with xelatex installed?):\n${p.out}`);
  if (p.out) ctx.notes.push(...p.out.split(/\r?\n/).map((l) => `latex: ${l}`));
  if (o.preview) ctx.previews.pdf = pdfToPngs(outPdf, previewDir(o, 'pdf'));
}

function buildOffice(o, ctx, kind, outFile) {
  const pandoc = needTool('pandoc');
  const kitRef = path.join(TPL, kind === 'pptx' ? 'reference.pptx' : ctx.style === 'akademik' ? 'reference-akademik.docx' : 'reference.docx');
  const ref = o.ref && path.extname(o.ref).toLowerCase() === `.${kind}` ? o.ref : kitRef;
  const args = [ctx.inputName, '-o', outFile, `--reference-doc=${ref}`];
  if (kind === 'pptx') args.push('--slide-level=2');
  else args.push(`--lua-filter=${path.join(TPL, 'number-captions.lua')}`);
  commonArgs(args, o, ctx, kind === 'docx');
  // Mendeley-style citation blocks; must come after --citeproc (pushed by commonArgs).
  if (kind === 'docx' && ctx.fm.bibliography) args.push(`--lua-filter=${path.join(TPL, 'citation-fields.lua')}`);
  const p = run(pandoc, args, { cwd: ctx.mdDir });
  if (!p.ok) die(`pandoc failed:\n${p.out}`);
  if (p.out) ctx.notes.push(...p.out.split(/\r?\n/).map((l) => `pandoc: ${l}`));
}

// DOCX/PPTX -> PDF with Microsoft Office (Windows) or LibreOffice. Returns the engine name or null.
function officeToPdf(file, outPdf) {
  const ext = path.extname(file).toLowerCase();
  if (IS_WIN) {
    const q = (s) => `'${s.replace(/'/g, "''")}'`;
    const script = ext === '.pptx'
      ? `$ErrorActionPreference='Stop'; $a = New-Object -ComObject PowerPoint.Application; try { $p = $a.Presentations.Open(${q(file)}, -1, 0, 0); $p.SaveAs(${q(outPdf)}, 32); $p.Close() } finally { $a.Quit() }`
      : `$ErrorActionPreference='Stop'; $a = New-Object -ComObject Word.Application; try { $a.Visible = $false; $a.DisplayAlerts = 0; $d = $a.Documents.Open(${q(file)}, $false, $true); $d.SaveAs2(${q(outPdf)}, 17); $d.Close($false) } finally { $a.Quit() }`;
    const r = run('powershell.exe', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', script], { timeout: 180000 });
    if (r.ok && fs.existsSync(outPdf)) return ext === '.pptx' ? 'PowerPoint' : 'Word';
  }
  const soffice = findTool('soffice');
  if (soffice) {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'docbuild-'));
    const r = run(soffice, ['--headless', '--convert-to', 'pdf', '--outdir', tmp, file], { timeout: 180000 });
    const produced = path.join(tmp, `${path.basename(file, ext)}.pdf`);
    if (r.ok && fs.existsSync(produced)) {
      fs.copyFileSync(produced, outPdf);
      fs.rmSync(tmp, { recursive: true, force: true });
      return 'LibreOffice';
    }
    fs.rmSync(tmp, { recursive: true, force: true });
  }
  return null;
}

function previewDir(o, kind) {
  const dir = path.join(o.outDir, `${o.name}-preview`, kind);
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function listPngs(dir) {
  return fs.readdirSync(dir).filter((f) => f.endsWith('.png')).sort().map((f) => path.join(dir, f));
}

function pdfToPngs(pdf, dir) {
  const pdftoppm = findTool('pdftoppm');
  if (pdftoppm && run(pdftoppm, ['-r', '60', '-png', pdf, path.join(dir, 'page')]).ok) return listPngs(dir);
  for (const py of IS_WIN ? ['python', 'py'] : ['python3', 'python']) {
    const code = 'import sys, pymupdf\nd = pymupdf.open(sys.argv[1])\nfor i, p in enumerate(d): p.get_pixmap(dpi=60).save(f"{sys.argv[2]}/page-{i + 1:02d}.png")';
    if (run(py, ['-c', code, pdf, dir]).ok) return listPngs(dir);
  }
  return null;
}

function rel(p) {
  return path.relative(process.cwd(), p) || p;
}

function main() {
  const o = parseArgs(process.argv.slice(2));
  if (!fs.existsSync(o.input)) die(`file not found: ${o.input}`, 2);
  const text = fs.readFileSync(o.input, 'utf8');
  const { fm, body } = frontMatter(text);
  const style = o.style || fm.docstyle || 'laporan';
  if (!STYLES.includes(style)) die(`unknown style "${style}" - use ${STYLES.join(', ')}`, 2);
  if (!['typst', 'latex'].includes(o.engine)) die(`unknown engine "${o.engine}" - use typst or latex`, 2);
  const slides = style === 'slides';
  const to = o.to || (slides ? 'pptx' : 'pdf');
  const kinds = to === 'all' ? (slides ? ['pptx', 'pdf'] : ['pdf', 'docx']) : [to];
  for (const k of kinds) if (!['pdf', 'docx', 'pptx'].includes(k)) die(`unknown format "${k}" - use pdf, docx, pptx or all`, 2);
  if (slides && kinds.includes('docx')) die('docstyle: slides builds pptx (and pdf from it), not docx', 2);
  if (!slides && kinds.includes('pptx')) die('pptx needs a slide document: set `docstyle: slides` and write one `##` heading per slide (see templates/documents/contoh-slides.md)', 2);

  const mdDir = path.dirname(o.input);
  o.name = o.name || path.basename(o.input, path.extname(o.input));
  o.outDir = path.resolve(o.out || mdDir);
  fs.mkdirSync(o.outDir, { recursive: true });
  const ctx = { fm, style, mdDir, inputName: path.basename(o.input), notes: [], previews: {} };

  console.log(`doc-build: ${rel(o.input)} (style ${style}, lang ${fm.lang || 'id'})`);
  const fmtWarns = formatChecks(body, mdDir, style, fm);
  const cslWarn = fmtWarns.find((w) => w.startsWith('front matter csl:'));
  if (cslWarn) die(cslWarn, 2);
  const results = [];

  for (const kind of kinds) {
    const out = path.join(o.outDir, `${o.name}.${kind}`);
    if (kind === 'pdf' && slides) {
      // Slide PDF = the pptx exported by an office suite, so both look the same.
      const pptx = path.join(o.outDir, `${o.name}.pptx`);
      if (!fs.existsSync(pptx) || !kinds.includes('pptx')) buildOffice(o, ctx, 'pptx', pptx);
      const engine = officeToPdf(pptx, out);
      if (!engine) die('slide PDF needs PowerPoint (Windows) or LibreOffice to export the pptx; the pptx itself was built');
      results.push({ kind, out, engine });
      if (o.preview) ctx.previews.pdf = pdfToPngs(out, previewDir(o, 'pdf'));
    } else if (kind === 'pdf') {
      if (o.engine === 'latex') buildLatexPdf(o, ctx, out); else buildTypstPdf(o, ctx, out);
      results.push({ kind, out, engine: o.engine });
    } else {
      buildOffice(o, ctx, kind, out);
      results.push({ kind, out, engine: 'pandoc' });
      if (o.preview && !(kind === 'pptx' && kinds.includes('pdf'))) {
        const tmpPdf = path.join(os.tmpdir(), `docbuild-${process.pid}-${kind}.pdf`);
        const engine = officeToPdf(out, tmpPdf);
        if (engine) {
          ctx.previews[kind] = pdfToPngs(tmpPdf, previewDir(o, kind));
          results[results.length - 1].pages = pageCount(tmpPdf);
          results[results.length - 1].previewEngine = engine;
          fs.rmSync(tmpPdf, { force: true });
        } else {
          ctx.previews[kind] = null;
        }
      }
    }
  }

  for (const r of results) {
    if (r.kind === 'pdf') r.pages = pageCount(r.out);
    const pages = r.pages ? `, ${r.pages} page${r.pages > 1 ? 's' : ''}` : '';
    console.log(`  ${r.kind.padEnd(5)} ${rel(r.out)} (${r.engine}${pages})`);
  }
  for (const [kind, pngs] of Object.entries(ctx.previews)) {
    if (pngs && pngs.length) {
      const via = results.find((r) => r.kind === kind)?.previewEngine;
      console.log(`  preview ${kind}: ${pngs.length} PNG in ${rel(path.dirname(pngs[0]))}${via ? ` (rendered by ${via})` : ''}`);
    } else {
      console.log(`  preview ${kind}: not available (needs ${kind === 'pdf' ? 'pdftoppm or Python pymupdf' : 'Microsoft Office or LibreOffice'}) - open the file and look instead`);
    }
  }
  const notes = [...fmtWarns.map((w) => `format: ${w}`), ...ctx.notes].filter(Boolean);
  if (notes.length) {
    console.log('  notes:');
    for (const n of notes) console.log(`    ${n}`);
  }

  let errors = 0;
  if (o.check) {
    const { issues } = checkMarkdown(text, { slides });
    errors = issues.filter((i) => i.level === 'error').length;
    const warns = issues.filter((i) => i.level === 'warn').length;
    console.log(`  doc-check: ${errors} error(s), ${warns} warning(s)`);
    for (const i of issues.filter((x) => x.level !== 'info').sort((a, b) => a.line - b.line)) {
      console.log(`    ${i.line ? `line ${i.line}` : 'whole doc'}: [${i.level}] ${i.msg}`);
    }
  }
  if (o.preview) console.log('  next: look at every preview page (title, headings near page ends, tables, images, lists) before you call it done');
  process.exit(errors ? 3 : 0);
}

main();
