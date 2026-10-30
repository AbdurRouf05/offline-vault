#!/usr/bin/env node
// Workflow Kit - project snapshot for the start of a session (and before writing docs/HANDOFF.md).
// Shows git state, how fresh the handoff is, the next steps from PROGRESS.md, and open markers,
// so a new model can check the handoff against reality in one command. Read-only.
//
// Usage: node .agents/scripts/snapshot.mjs [project dir]

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const root = path.resolve(process.argv[2] || '.');
const docs = (f) => path.join(root, 'docs', f);

function git(...args) {
  const r = spawnSync('git', args, { cwd: root, encoding: 'utf8' });
  return r.status === 0 ? r.stdout.trim() : null;
}

function section(file, title) {
  if (!fs.existsSync(file)) return null;
  const text = fs.readFileSync(file, 'utf8');
  const m = text.match(new RegExp(`^##\\s+${title}[^\\n]*\\n([\\s\\S]*?)(?=^##\\s|(?![\\s\\S]))`, 'm'));
  return m ? m[1].split(/\r?\n/).filter((l) => l.trim() && !l.trim().startsWith('<!--')) : null;
}

function lines(file) {
  return fs.existsSync(file) ? fs.readFileSync(file, 'utf8').split(/\r?\n/).length : 0;
}

function age(ms) {
  const h = Math.round(ms / 36e5);
  return h < 1 ? 'less than an hour ago' : h < 48 ? `${h} hours ago` : `${Math.round(h / 24)} days ago`;
}

const out = [];
const say = (s = '') => out.push(s);
const now = new Date();
const pad = (n) => String(n).padStart(2, '0');
const stamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
say(`snapshot: ${root}  (${stamp})`);

const inGit = git('rev-parse', '--is-inside-work-tree') === 'true';
if (inGit) {
  const branch = git('rev-parse', '--abbrev-ref', 'HEAD') || '?';
  const dirty = (git('status', '--porcelain') || '').split('\n').filter(Boolean);
  const ab = git('rev-list', '--left-right', '--count', 'HEAD...@{u}');
  const upstream = ab ? (() => { const [a, b] = ab.split(/\s+/); return `, ahead ${a} / behind ${b} of upstream`; })() : ', no upstream';
  say(`git: branch ${branch}, ${dirty.length} uncommitted file(s)${upstream}`);
  for (const d of dirty.slice(0, 8)) say(`  ${d}`);
  if (dirty.length > 8) say(`  ... ${dirty.length - 8} more`);
  const log = git('log', '-6', '--format=%h %cr  %s');
  if (log) { say('last commits:'); for (const l of log.split('\n')) say(`  ${l}`); }
} else {
  say('git: not a git repository (or git not installed)');
}

say();
const handoff = docs('HANDOFF.md');
if (fs.existsSync(handoff)) {
  const mtime = fs.statSync(handoff).mtimeMs;
  let fresh = `edited ${age(Date.now() - mtime)}`;
  let stale = false;
  if (inGit) {
    const last = git('log', '-1', '--format=%H', '--', 'docs/HANDOFF.md');
    if (last) {
      const since = Number(git('rev-list', '--count', `${last}..HEAD`) || 0);
      const pending = (git('status', '--porcelain', '--', 'docs/HANDOFF.md') || '') !== '';
      fresh += `, ${since} commit(s) since it was last committed${pending ? ' (newer version not committed yet)' : ''}`;
      stale = since >= 5 && !pending;
    } else {
      fresh += ', never committed';
    }
  }
  say(`docs/HANDOFF.md: ${lines(handoff)} lines, ${fresh}${stale ? '  -> STALE: check it against the commits above, then refresh it' : ''}`);
  const tldr = section(handoff, 'TL;DR');
  if (tldr) for (const l of tldr.slice(0, 4)) say(`  ${l}`);
} else {
  say('docs/HANDOFF.md: missing -> create it from .agents/templates/HANDOFF.md (skill wf-handoff, Save)');
}

const next = section(docs('PROGRESS.md'), 'Next steps');
if (next) {
  say('docs/PROGRESS.md next steps:');
  for (const l of next.slice(0, 5)) say(`  ${l.trim()}`);
} else {
  say(`docs/PROGRESS.md: ${fs.existsSync(docs('PROGRESS.md')) ? 'no "Next steps" section' : 'missing'}`);
}

const chatlog = docs('CHATLOG.md');
if (fs.existsSync(chatlog)) {
  const n = lines(chatlog);
  const entries = (fs.readFileSync(chatlog, 'utf8').match(/^###\s/gm) || []).length;
  say(`docs/CHATLOG.md: ${n} lines, ${entries} entries${n > 1500 ? '  -> move older months to docs/archive/ (see the template header)' : ''}`);
}

if (inGit) {
  const count = (pattern) => {
    const r = git('grep', '-I', '-c', '-E', pattern, '--', '.', ':(exclude).agents', ':(exclude)docs', ':(exclude)AGENTS.md');
    return r ? r.split('\n').reduce((s, l) => s + Number(l.split(':').pop() || 0), 0) : 0;
  };
  const assumptions = count('ASSUMPTION\\(');
  const todos = count('\\b(TODO|FIXME)\\b');
  say(`markers in code: ${assumptions} ASSUMPTION, ${todos} TODO/FIXME${assumptions ? ' (see PROGRESS.md "Open questions (marathon)")' : ''}`);
}

console.log(out.join('\n'));
