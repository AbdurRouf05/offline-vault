# AGENTS.md — Operating Manual

This project uses the **Workflow Kit**. These rules apply to EVERY task and override your default habits.
Follow them literally. When a rule and your instinct disagree, the rule wins.

## 0. Language & defaults

- Talk to the user in **Bahasa Indonesia** (clear, casual-professional). No emoji.
- Code, identifiers, code comments, commit messages: **English**.
- Project docs: the language set in `docs/PROJECT.md` → "Docs language" (default: English).
- **JS/TS package manager: pnpm** (`pnpm add`, `pnpm dlx`, `pnpm create`). Never npm/yarn/npx unless the project
  already has another lockfile.
- Kit scripts run with Node (`node .agents/scripts/<name>.mjs`). Shell hooks need `sh`; on Windows without it on PATH
  use Git's: `& "$env:ProgramFiles\Git\bin\sh.exe" <script>`.

## 1. Start of EVERY task (mandatory, even mid-conversation)

The AI model serving this project may change between messages (routers, fallbacks, different tools).
**Chat history is not memory. Files are memory.**

1. Re-read §3–§5 of this file. Then read, if they exist: `docs/HANDOFF.md` **first** (where work stopped, what is
   half-done, next steps), then `docs/PROGRESS.md` and `docs/PROJECT.md`. New session or new model → follow the Resume
   mode of `.agents/skills/wf-handoff/SKILL.md` (includes `node .agents/scripts/snapshot.mjs` to check git reality).
2. Read `docs/PRD.md` when the task changes behavior; `docs/DESIGN.md` when it touches UI or text users see;
   `docs/DATABASE.md` when it touches data or the schema.
3. No `docs/` and no code → idea still vague or user wants to discuss → `wf-brainstorm`; idea clear → `wf-new-project`.
   No `docs/` but code exists → skill `wf-onboard` first.
4. Log the user's message verbatim in `docs/CHATLOG.md` (`node .agents/scripts/chatlog.mjs user`, see wf-handoff).
5. Continue from the next steps in `docs/HANDOFF.md` / `docs/PROGRESS.md` unless the user asks for something else.

## 2. Route the task

First, size it:

- **Tiny**: 1 file, obvious change, under ~20 lines, no new behavior risk (typo, rename, copy change, small style fix).
  → Do it directly, run verify, add one log line to `docs/PROGRESS.md`, commit.
- **Anything bigger** → open the matching skill file and follow it step by step:

| User wants…                                          | Read and follow                               |
|------------------------------------------------------|-----------------------------------------------|
| Discuss / brainstorm an idea, find open-source refs  | `.agents/skills/wf-brainstorm/SKILL.md`       |
| New project / app / tool / script, or a PRD          | `.agents/skills/wf-new-project/SKILL.md`      |
| Adopt this workflow in an existing codebase          | `.agents/skills/wf-onboard/SKILL.md`          |
| Add or change a feature                              | `.agents/skills/wf-feature/SKILL.md`          |
| Design system, UI, layout, styling, copywriting      | `.agents/skills/wf-design/SKILL.md`           |
| Fix a bug / error / crash / wrong behavior           | `.agents/skills/wf-bugfix/SKILL.md`           |
| Clean up / restructure code without new behavior     | `.agents/skills/wf-refactor/SKILL.md`         |
| Review code, a diff, or a PR                         | `.agents/skills/wf-code-review/SKILL.md`      |
| Security check / find vulnerabilities                | `.agents/skills/wf-security-audit/SKILL.md`   |
| Marathon: build everything end to end on your own   | `.agents/skills/wf-marathon/SKILL.md`         |
| Add / fix end-to-end tests (Playwright)              | `.agents/knowledge/testing.md` → "E2E with Playwright" |
| Deploy / release / publish / build installer         | `.agents/skills/wf-release/SKILL.md`          |
| Write / edit / convert a document or slides (PDF, DOCX, PPTX): laporan, proposal, makalah, surat, presentasi | `.agents/skills/wf-docs/SKILL.md` |
| Research / penelitian / skripsi / jurnal: find papers and data, read PDFs, write with citations | `.agents/skills/wf-research/SKILL.md` |
| Read a PDF / DOCX / PPTX precisely (formulas, tables, figures, code) | `.agents/knowledge/reading.md` |
| Save or restore context: "simpan dulu", "lanjut(kan)", new session, model switch, long chat | `.agents/skills/wf-handoff/SKILL.md` |

If unsure which one fits, pick the closest and tell the user which one you picked.

## 3. Non-negotiable rules

1. **Read before you write.** Never edit a file you have not read in this session. Search for existing helpers/patterns
   before creating new ones, and follow the existing style.
2. **Don't guess on unclear or costly decisions — grill the user** (`.agents/knowledge/grill-me.md`): the interactive
   question tool with options + Other, a recommendation, pros/cons. Cheap to undo → sensible default, stated as assumption.
3. **Plan before code** for anything not Tiny (`.agents/templates/PLAN.md`). Show the plan before implementing.
4. **Small steps, atomic commits.** One step → verify → commit → next. Each commit is one complete logical change that
   passes verify (`.agents/knowledge/git.md`). Change only what the task needs.
5. **Clean, modular code.** Feature modules with a public entry point, no cross-module deep imports, one job per
   function/file (`.agents/knowledge/code-quality.md`).
6. **Never invent** APIs, functions, packages, versions, CLI flags, or config keys. Check the installed package (types,
   source, `--help`) or official docs. If you cannot verify, say so.
7. **Verify before claiming done.** Run the verify command (`docs/PROJECT.md` → Commands) and report the real result.
   "Should work" without running anything is forbidden.
8. **Security baseline, always** (`.agents/knowledge/security.md`): no secrets in code/git, validate input on the server,
   parameterized queries, authorization check on every protected action.
9. **No AI-slop UI or copy.** Follow `docs/DESIGN.md` and the banned list in `.agents/knowledge/ui-ux.md` and
   `.agents/knowledge/copywriting.md`. No gradients, one-side accent borders, emoji icons, decorative badges,
   default dark/space themes, or hype words. Documents for people follow `.agents/knowledge/writing.md`:
   paragraphs for explanations, lists only where content is a real list.
10. **Keep memory updated.** Every commit that changes code also updates `docs/PROGRESS.md` (a git hook enforces this).
    Significant decisions → ADR in `docs/decisions/`. **Save the handoff** (`wf-handoff`, Save mode: overwrite
    `docs/HANDOFF.md`) after every finished task, and as soon as the chat gets long (about 15 user messages, many
    large files read, or a "context compacted" notice). Do not wait to be asked: chat context will be lost, files will not.
11. **Be honest.** Report failures, skipped steps, and uncertainty plainly. Never silence an error, skip a hook
    (`--no-verify`), or weaken a test to make things "pass".
12. **Changes against the plan are confirmed first, every time.** If a request breaks a kit rule, or contradicts a
    recorded decision (`docs/PRD.md`, `DESIGN.md`, `PROJECT.md` stack, `decisions/`, `PLAN`, `IDEA.md`,
    `research/RESEARCH.md`, decisions in `HANDOFF.md`) or something the user said earlier (`docs/CHATLOG.md`): do not
    just do it, and do not silently refuse. Ask with the change check in `.agents/knowledge/grill-me.md` →
    "Change check": what was decided at first (file, date, why), what is asked now, the impact, then options.
    After the answer, record it (ADR + update the doc that held the old decision). This applies even when the
    user sounds sure, and even in wf-marathon.

## 4. STOP and ask the user before

- Deleting files, data, branches, or tables; destructive migrations; `git push --force`; rewriting history.
- Changing the tech stack, adding a paid service, or adding a large dependency.
- Doing anything that contradicts a recorded decision or an earlier user statement (rule 12, "Change check").
- Changing auth, payments, permissions, or encryption beyond what the task asked.
- Touching production, real credentials, or real user data.
- **Stuck rule:** the same problem survived 2 fix attempts → stop. Revert experiments, summarize what you tried and
  learned, propose 2–3 options.

## 5. Definition of Done (every non-Tiny task)

- [ ] Acceptance criteria met — each one checked, not assumed.
- [ ] Verify command passes (format, lint, type-check, tests). Output actually seen.
- [ ] New/changed behavior has tests; critical user flows have E2E tests (`.agents/knowledge/testing.md`).
- [ ] Self-review of the diff with the checklist in `.agents/knowledge/code-quality.md`.
- [ ] Security checklist applied if the change touches input, auth, data, files, or external calls.
- [ ] UI/copy checked against `docs/DESIGN.md` and the anti-slop lists (if UI changed).
- [ ] `docs/PROGRESS.md` updated; PRD updated if scope/behavior changed; ADR if a significant decision was made;
      README/CHANGELOG if user-facing.
- [ ] `docs/HANDOFF.md` overwritten with the current state; `docs/CHATLOG.md` has every user message of this chat.
- [ ] Documents: `doc-check` has no errors and every preview page was looked at (`.agents/knowledge/documents.md`).
- [ ] Atomic commit(s) with conventional messages. No debug leftovers.

## 6. Report format (end of every task)

```
Selesai: <what was done, 1–3 bullets>
Verifikasi: <command run> -> <result>
Progress: docs/PROGRESS.md + docs/HANDOFF.md diperbarui (ya / tidak + alasan)
Commit: <hash + message, or "belum">
Catatan: <skipped items, risks, assumptions>
Berikutnya: <recommended next step>
```

## 7. Knowledge map (read when relevant, not all at once)

| Topic                                        | File                                    |
|----------------------------------------------|-----------------------------------------|
| Choosing a tech stack                        | `.agents/knowledge/stack-selection.md`  |
| Architecture, layers, folder structure       | `.agents/knowledge/architecture.md`     |
| Database schema (mermaid + DBML, visual)     | `.agents/templates/DATABASE.md`         |
| Asking the user (grill me)                   | `.agents/knowledge/grill-me.md`         |
| Open-source research, licenses & reuse       | `.agents/knowledge/oss-research.md`     |
| Clean modular code & self-review checklist   | `.agents/knowledge/code-quality.md`     |
| Testing & E2E (Playwright)                   | `.agents/knowledge/testing.md`          |
| Security checklist                           | `.agents/knowledge/security.md`         |
| Quality gates (lint/test/verify/hooks)       | `.agents/knowledge/quality-gates.md`    |
| Documentation (PRD, DESIGN, PROGRESS, ADR)   | `.agents/knowledge/documentation.md`    |
| UI quality & anti-slop rules                 | `.agents/knowledge/ui-ux.md`            |
| Copywriting (UI text)                        | `.agents/knowledge/copywriting.md`      |
| Git, atomic commits                          | `.agents/knowledge/git.md`              |
| Writing documents (paragraph-first, EYD)     | `.agents/knowledge/writing.md`          |
| Document formats, build, checks (PDF/DOCX/PPTX) | `.agents/knowledge/documents.md`    |
| Context handoff (HANDOFF, CHATLOG)           | `.agents/skills/wf-handoff/SKILL.md`    |
| Where to find papers & data, quality, legality | `.agents/knowledge/research-sources.md` |
| Reading PDF/DOCX/PPTX precisely              | `.agents/knowledge/reading.md`          |
| Tools installed? (pandoc, typst, python libs) | `node .agents/scripts/tools-check.mjs` |

## 8. Project-specific rules

<!-- Add rules that apply only to this project below. Keep them short. -->
