---
name: wf-handoff
description: Keep the project's working memory on disk so no context is lost when the chat gets long, the model changes, or a new session starts. Save mode writes docs/HANDOFF.md (overwritten snapshot), appends docs/CHATLOG.md (every user message verbatim plus a short AI summary) and updates docs/PROGRESS.md. Resume mode reads them, checks them against git, and continues. Use at the start of every session, after every finished task, when the chat is long, or when the user says "lanjut", "lanjutkan", "simpan dulu", "handoff", "ganti model", "sesi baru".
---

# wf-handoff — Never lose the thread

Chat context is temporary: it gets cut, summarized, or lost when the model or session changes. Cheap models also start
forgetting early details long before the window is full. The fix is to keep the memory in files, written so that a
model which knows nothing can pick up the work in one read.

| File | Role | How it is written |
|---|---|---|
| `docs/HANDOFF.md` | Where we are right now, what is half-done, the next 3 steps | **Overwritten** each save, max ~150 lines |
| `docs/CHATLOG.md` | Full history: every user message verbatim + 1-2 line AI summary | **Append-only**, every turn |
| `docs/PROGRESS.md` | Task tracker: state, next steps, backlog, log | Updated per task |
| `docs/PROJECT.md`, `docs/decisions/` | Stable facts (stack, commands) and decisions (ADRs) | Rarely, when they change |

## Every turn: log the conversation
1. At the **start** of a turn, append the user's message to `docs/CHATLOG.md`, verbatim:
   ```bash
   node .agents/scripts/chatlog.mjs user --model "<your model/tool if known>" <<'EOF'
   <the user's message exactly as written, typos included>
   EOF
   ```
   PowerShell: `$OutputEncoding = [Text.UTF8Encoding]::new($false)`, then
   `@'` + newline + message + newline + `'@ | node .agents/scripts/chatlog.mjs user --model "<model>"`.
   No shell? Append the entry with your edit tool in the format shown in the file header.
2. At the **end** of the turn, append what you did: `node .agents/scripts/chatlog.mjs ai "<1-2 lines: what was done, files/commits>"`.
   A `**User:**` block with no `**AI:**` line after it means that turn was interrupted.
3. Very short messages ("ok", "lanjut", "ya") are logged too; they show what the user approved.

## Save mode
### When to save (do not wait to be asked)
- After **every finished task**, before the final report (it is part of the DoD in `AGENTS.md` §5).
- When the chat is **long**. You usually cannot see the token count, so use these signals:
  - about 15 user messages since the last save (about 8 if the turns were heavy: big files, long logs, many tool calls);
  - you have read more than ~10 large files or long outputs in this chat;
  - the tool says the context was compacted or summarized, or warns that it is nearly full;
  - you are unsure what the user said earlier, or you are re-reading files you already read.
- Before something risky or long (big refactor, migration, marathon run), and before stopping for the day.
- When the user says "simpan dulu", "handoff", "ganti model", "sesi baru", "besok lanjut".

### How to save
1. Make sure `docs/CHATLOG.md` has every user message of this chat (add missing ones now, verbatim).
2. Run `node .agents/scripts/snapshot.mjs` to get the real git state (branch, uncommitted files, last commits).
3. **Overwrite** `docs/HANDOFF.md` using the structure of `.agents/templates/HANDOFF.md`. Rules:
   - Write for a stranger: a different, weaker model reads this with zero chat history.
   - Concrete: file paths, function names, exact commands, exact error messages, commit hashes. Never "as discussed",
     "the bug above", "that file".
   - "In flight" says exactly where work stopped: which file, which step, what is half-done or broken right now.
   - Absolute dates (2026-10-25), not "yesterday".
   - Quote the user's own words for requirements and preferences that matter (short quotes).
   - Remove what is no longer true. It is a snapshot, not a diary; history lives in CHATLOG and PROGRESS.
   - No secrets (passwords, tokens, keys): write where they are configured, never their values.
4. Update `docs/PROGRESS.md` (Current state, Next steps, Log) so it agrees with the handoff.
5. Commit following `.agents/knowledge/git.md`: together with the task's commit, or alone as `docs: update handoff`.
6. **Cold-start test.** Re-read HANDOFF.md as if you knew nothing. Could you do the next step without asking "what were
   we doing?" If not, fix it.

### When the chat is long, tell the user
After saving because of length, say (in Indonesian):
"Percakapan ini sudah panjang dan model bisa mulai lupa detail awal. Semua sudah saya simpan di `docs/HANDOFF.md` dan
`docs/CHATLOG.md`. Disarankan buka chat baru dan ketik: **lanjutkan dari handoff**."
Then continue the current task if the user wants to stay; do not stop work on your own.

## Resume mode
Use at the start of every session (`AGENTS.md` §1), and whenever the user says "lanjut(kan)", "lanjutkan dari handoff",
or the model was just switched.
1. Read `docs/HANDOFF.md` fully. Missing? Read `docs/PROGRESS.md`; if code exists but there are no docs, use `wf-onboard`.
2. Read `docs/PROGRESS.md` (Current state, Next steps, Open questions).
3. Run `node .agents/scripts/snapshot.mjs`. Compare with the handoff:
   - commits newer than the handoff, or uncommitted files it does not mention → the handoff is behind. Trust git and the
     code, read the diff (`git log -p -3`, `git diff`), and note the drift in your summary;
   - snapshot says STALE → refresh the handoff (Save mode) after you understand the current state.
4. Read the last ~5 entries of `docs/CHATLOG.md` (`tail -n 60 docs/CHATLOG.md`). Read further back only when the user
   refers to something older or the handoff is unclear; never load the whole file by default.
5. Read the files listed under "Read first".
6. Tell the user in 3-6 lines (Indonesian): what the project is, where we stopped, what is half-done, the next step.
   - Next step clear and already agreed with the user → start it.
   - Otherwise, or if the handoff has open questions → ask with the grill-me tool (`.agents/knowledge/grill-me.md`).

## Keeping files healthy
- `HANDOFF.md` over ~150 lines → cut history and finished items; move lasting facts to PROJECT.md or an ADR.
- `CHATLOG.md` over ~1500 lines → move whole older months to `docs/archive/CHATLOG-YYYY-MM.md`, leave a pointer line.
- Never rewrite old CHATLOG entries. A wrong summary gets a correction in a new entry.
