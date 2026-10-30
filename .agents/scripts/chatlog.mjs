#!/usr/bin/env node
// Workflow Kit - append an entry to docs/CHATLOG.md in the standard format.
// The message comes from stdin (or --file) so quotes, $ and line breaks survive the shell untouched.
//
// Usage:
//   node .agents/scripts/chatlog.mjs user [--model "<name>"] [--file msg.txt] [--full]   (message on stdin)
//   node .agents/scripts/chatlog.mjs ai "<1-2 line summary of what was done>"
//
//   bash:        node .agents/scripts/chatlog.mjs user --model "Gemini" <<'EOF'
//                <user message, verbatim>
//                EOF
//   PowerShell:  $OutputEncoding = [Text.UTF8Encoding]::new($false)
//                @'
//                <user message, verbatim>
//                '@ | node .agents/scripts/chatlog.mjs user --model "Gemini"
//
// Messages over 120 lines (pasted logs/code) keep the first 40 lines unless --full is given.
// Obvious secrets (API keys, tokens, private keys) are replaced with [redacted].

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE = path.join(SCRIPT_DIR, '..', 'templates', 'CHATLOG.md');

const args = process.argv.slice(2);
const kind = args.shift();
const opt = { model: '', file: '', dir: '.', full: false };
const rest = [];
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--model') opt.model = args[++i] || '';
  else if (a === '--file') opt.file = args[++i] || '';
  else if (a === '--dir') opt.dir = args[++i] || '.';
  else if (a === '--full') opt.full = true;
  else rest.push(a);
}

function usage(msg) {
  if (msg) console.error(`chatlog: ${msg}`);
  console.error('usage: chatlog.mjs user [--model NAME] [--file F] [--full] < message  |  chatlog.mjs ai "summary"');
  process.exit(2);
}
if (kind !== 'user' && kind !== 'ai') usage();

function readInput() {
  if (opt.file) return fs.readFileSync(opt.file, 'utf8');
  if (rest.length) return rest.join(' ');
  if (process.stdin.isTTY) usage('no message on stdin');
  return fs.readFileSync(0, 'utf8');
}

const SECRETS = [
  /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g,
  /\b(sk|pk|rk)-[A-Za-z0-9_-]{20,}/g,
  /\bgh[pousr]_[A-Za-z0-9]{30,}/g,
  /\bgithub_pat_[A-Za-z0-9_]{30,}/g,
  /\bAKIA[0-9A-Z]{16}\b/g,
  /\bAIza[0-9A-Za-z_-]{35}\b/g,
  /\bxox[abpr]-[A-Za-z0-9-]{10,}/g,
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g,
];
const redact = (s) => SECRETS.reduce((t, re) => t.replace(re, '[redacted]'), s);

const pad = (n) => String(n).padStart(2, '0');
const d = new Date();
const stamp = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;

let text = redact(readInput().replace(/^﻿/, '').replace(/\r\n?/g, '\n')).replace(/\s+$/, '');
if (!text.trim()) usage('empty message');

let entry;
if (kind === 'user') {
  let lines = text.split('\n');
  if (!opt.full && lines.length > 120) {
    const cut = lines.length - 40;
    lines = [...lines.slice(0, 40), `[truncated: ${cut} more lines of pasted text]`];
  }
  const quoted = lines.map((l) => (l.trim() ? `> ${l}` : '>')).join('\n');
  entry = `\n### ${stamp}${opt.model ? ` · ${opt.model}` : ''}\n**User:**\n${quoted}\n`;
} else {
  entry = `\n**AI:** ${text.replace(/\n+/g, ' ')}\n`;
}

const file = path.resolve(opt.dir, 'docs', 'CHATLOG.md');
if (!fs.existsSync(file)) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, fs.existsSync(TEMPLATE) ? fs.readFileSync(TEMPLATE, 'utf8') : '# Chat log\n');
}
const current = fs.readFileSync(file, 'utf8');
fs.appendFileSync(file, (current.endsWith('\n') ? '' : '\n') + entry);

const total = current.split('\n').length + entry.split('\n').length - 1;
console.log(`chatlog: ${kind} entry appended to docs/CHATLOG.md (${total} lines)`);
if (total > 1500) console.log('chatlog: over 1500 lines -> move older months to docs/archive/ (see the file header)');
