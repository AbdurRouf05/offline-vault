#!/usr/bin/env node
// Workflow Kit - which tools are installed? Read-only: it never installs anything.
// Use it before wf-docs / wf-research / reading a PDF, so you know what works on this machine
// instead of guessing. Prints what is missing and the exact install command for this OS.
//
// Usage: node .agents/scripts/tools-check.mjs [--for docs|research|read|all] [--json]
//   --for   only the tools that job needs (default: all). Exit 1 if a REQUIRED tool for it is missing.
//   --json  machine-readable output
//
// After it runs: if something required is missing, ASK the user once (grill-me) whether to install it, record the
// answer in docs/PROJECT.md -> "Tools setup", then install in the background (see .agents/knowledge/reading.md ->
// "Setup"). Never install without asking.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const IS_WIN = process.platform === 'win32';
const IS_MAC = process.platform === 'darwin';
const args = process.argv.slice(2);
const json = args.includes('--json');
const forIdx = args.indexOf('--for');
const job = forIdx >= 0 ? args[forIdx + 1] : 'all';
if (!['docs', 'research', 'read', 'all'].includes(job)) {
  console.error('usage: tools-check.mjs [--for docs|research|read|all] [--json]');
  process.exit(2);
}

function tryRun(cmd, cmdArgs, timeout = 20000) {
  const r = spawnSync(cmd, cmdArgs, { encoding: 'utf8', timeout, windowsHide: true });
  if (r.error || r.status !== 0) return null;
  return `${r.stdout || ''}${r.stderr || ''}`.trim();
}

function firstVersion(text) {
  const m = (text || '').match(/\d+\.\d+(\.\d+)?/);
  return m ? m[0] : 'yes';
}

// A CLI tool: first working candidate wins.
function cli(candidates, versionArgs = ['--version']) {
  for (const c of candidates) {
    if (c.includes(path.sep) && !fs.existsSync(c)) continue;
    const out = tryRun(c, versionArgs);
    if (out !== null) return { found: true, version: firstVersion(out), path: c };
  }
  return { found: false };
}

const local = process.env.LOCALAPPDATA || '';
const pf = process.env.ProgramFiles || 'C:\\Program Files';

// Python: python, python3, or the Windows launcher.
let py = null;
for (const cand of IS_WIN ? [['python'], ['py', '-3'], ['python3']] : [['python3'], ['python']]) {
  const out = tryRun(cand[0], [...cand.slice(1), '--version']);
  if (out && /Python 3\.(\d+)/.test(out)) { py = { cmd: cand, version: firstVersion(out) }; break; }
}
const pyCmd = py ? py.cmd.join(' ') : (IS_WIN ? 'python' : 'python3');

// Python packages, checked in one call: import name -> distribution name.
const PY_PKGS = {
  pymupdf: 'pymupdf', docx: 'python-docx', pptx: 'python-pptx', openpyxl: 'openpyxl',
  pandas: 'pandas', docling: 'docling',
};
let pyPkgs = {};
if (py) {
  const code = 'import importlib.util as u, importlib.metadata as m, json\n'
    + `pk=${JSON.stringify(PY_PKGS)}\n`
    + 'r={}\n'
    + 'for imp, dist in pk.items():\n'
    + '    ok = u.find_spec(imp) is not None\n'
    + '    v = None\n'
    + '    if ok:\n'
    + '        try: v = m.version(dist)\n'
    + '        except Exception: v = "yes"\n'
    + '    r[imp] = v\n'
    + 'print(json.dumps(r))';
  const out = tryRun(py.cmd[0], [...py.cmd.slice(1), '-c', code], 60000);
  try { pyPkgs = JSON.parse(out); } catch { pyPkgs = {}; }
}

function office() {
  if (IS_WIN) {
    const ps = 'foreach($p in "Word.Application","PowerPoint.Application"){ if([type]::GetTypeFromProgID($p)){$p} }';
    const out = tryRun('powershell', ['-NoProfile', '-Command', ps], 30000) || '';
    const apps = out.split(/\r?\n/).filter(Boolean).map((s) => s.split('.')[0]);
    if (apps.length) return { found: true, version: apps.join('+'), path: 'Microsoft Office (COM)' };
  }
  return cli([path.join(pf, 'LibreOffice', 'program', 'soffice.exe'), '/Applications/LibreOffice.app/Contents/MacOS/soffice', 'soffice', 'libreoffice']);
}

const pipInstall = (pkgs) => `${pyCmd} -m pip install --user ${pkgs}`;
const by = (win, mac, linux) => (IS_WIN ? win : IS_MAC ? mac : linux);

// need: which jobs require it (r) or can use it (o).
const TOOLS = [
  { name: 'node', what: 'runs the kit scripts', need: { docs: 'r', research: 'r', read: 'r' },
    check: () => ({ found: true, version: process.versions.node, path: process.execPath }), install: 'https://nodejs.org (LTS)' },
  { name: 'pandoc', what: 'Markdown -> PDF/DOCX/PPTX, citations (citeproc), DOCX -> text', need: { docs: 'r', research: 'r', read: 'o' },
    check: () => cli(['pandoc', path.join(local, 'Pandoc', 'pandoc.exe'), path.join(pf, 'Pandoc', 'pandoc.exe')]),
    install: by('winget install --id JohnMacFarlane.Pandoc', 'brew install pandoc', 'sudo apt install pandoc (or the .deb from pandoc.org for 3.x)') },
  { name: 'typst', what: 'PDF engine (default)', need: { docs: 'r', research: 'r' },
    check: () => cli(['typst', path.join(local, 'Microsoft', 'WinGet', 'Links', 'typst.exe'), path.join(os.homedir(), '.cargo', 'bin', IS_WIN ? 'typst.exe' : 'typst')]),
    install: by('winget install --id Typst.Typst', 'brew install typst', 'snap install typst (or cargo install typst-cli)') },
  { name: 'office', what: 'DOCX/PPTX -> PDF preview, slide PDF (Word/PowerPoint or LibreOffice)', need: { docs: 'o', research: 'o', read: 'o' },
    check: office, install: by('Microsoft Office, or: winget install --id TheDocumentFoundation.LibreOffice', 'brew install --cask libreoffice', 'sudo apt install libreoffice') },
  { name: 'xelatex', what: 'optional PDF engine (--engine latex)', need: { docs: 'o', research: 'o' },
    check: () => cli(['xelatex']), install: by('winget install --id MiKTeX.MiKTeX', 'brew install --cask mactex-no-gui', 'sudo apt install texlive-xetex') },
  { name: 'python', what: 'reading PDF/DOCX/PPTX (read-doc.py)', need: { research: 'r', read: 'r' },
    check: () => (py ? { found: true, version: py.version, path: pyCmd } : { found: false }),
    install: by('winget install --id Python.Python.3.12', 'brew install python', 'sudo apt install python3 python3-pip') },
  { name: 'pymupdf', what: 'PDF text, tables, images, page renders (required for PDF reading)', need: { research: 'r', read: 'r' }, py: true,
    install: pipInstall('pymupdf') },
  { name: 'python-docx', what: 'DOCX comments, tables, metadata', need: { research: 'o', read: 'r' }, py: 'docx',
    install: pipInstall('python-docx') },
  { name: 'python-pptx', what: 'PPTX slides, notes, tables', need: { research: 'o', read: 'r' }, py: 'pptx',
    install: pipInstall('python-pptx') },
  { name: 'openpyxl', what: 'Excel data files', need: { research: 'o' }, py: true, install: pipInstall('openpyxl') },
  { name: 'pandas', what: 'data cleaning and analysis', need: { research: 'o' }, py: true, install: pipInstall('pandas') },
  { name: 'docling', what: 'formulas -> LaTeX, hard layouts, scanned pages (OCR). Big install (~1-2 GB), run in background',
    need: { research: 'o', read: 'o' }, py: true, install: pipInstall('docling') },
];

const rows = TOOLS.filter((t) => job === 'all' || t.need[job]).map((t) => {
  let res;
  if (t.py) {
    const imp = typeof t.py === 'string' ? t.py : t.name;
    const v = py ? pyPkgs[imp] : null;
    res = v ? { found: true, version: v } : { found: false };
  } else {
    res = t.check();
  }
  const level = job === 'all' ? (Object.values(t.need).includes('r') ? 'required' : 'optional') : t.need[job] === 'r' ? 'required' : 'optional';
  return { name: t.name, level, ...res, what: t.what, install: res.found ? null : t.install };
});

const missingRequired = rows.filter((r) => !r.found && r.level === 'required');

if (json) {
  console.log(JSON.stringify({ job, os: process.platform, tools: rows }, null, 2));
} else {
  console.log(`tools-check (${job}) on ${process.platform}`);
  for (const r of rows) {
    const status = r.found ? `OK      ${r.version}` : r.level === 'required' ? 'MISSING' : 'missing';
    console.log(`  ${r.name.padEnd(12)} ${status.padEnd(18)} ${r.level.padEnd(9)} ${r.what}`);
  }
  const missing = rows.filter((r) => !r.found);
  if (missing.length) {
    console.log('\nInstall commands (ask the user first; big installs run in the background):');
    for (const r of missing) console.log(`  ${r.name.padEnd(12)} ${r.install}`);
  }
  console.log(missingRequired.length ? `\n${missingRequired.length} required tool(s) missing.` : '\nAll required tools are installed.');
}
process.exit(missingRequired.length ? 1 : 0);
