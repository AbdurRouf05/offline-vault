---
name: wf-marathon
description: Autonomous marathon mode - grill the user once up front, then build the whole backlog (or a big feature) end to end on your own - code, type-check, tests, E2E, atomic commits, docs - marking unclear points instead of stopping, and grilling them when the user says "lanjut"/"gaskan". Use when the user says marathon, kerjakan sampai selesai, full auto, gaskan, or wants you to do everything yourself.
---

# wf-marathon — Do it all, without pretending to know

Marathon = you work through many steps alone, verifying everything yourself. It is NOT permission to guess big things.
The balance: **ask everything that matters at the start, then run; mark what becomes unclear on the way.**

## Phase 0 — Load context
1. Read `AGENTS.md`, `docs/PROGRESS.md`, `docs/PRD.md`, `docs/PROJECT.md`, `docs/DESIGN.md`, `docs/DATABASE.md` (those that exist).
2. No PRD / no project yet → run `wf-new-project` (its checkpoints count as the up-front grill) and come back here.
3. Define the marathon target: which backlog items / user stories, in which order. Write it in `docs/PROGRESS.md` →
   "Marathon" section with a checklist.

## Phase 1 — Grill up front (once, thoroughly)
Go through every target story and list everything unclear or costly to undo (business rules, edge cases, data model,
roles, UI direction, integrations, copy). Ask them using `.agents/knowledge/grill-me.md` (interactive question tool;
chat format only as fallback), in rounds of max 4, until no important unknown is left.
Record answers in the PRD / DESIGN / DATABASE / ADR. Then tell the user in one line: what you will build, in what order.

## Phase 2 — Run (loop per story, no waiting)
For each story, follow `wf-feature` Steps 3–9 without stopping for confirmation:
1. Plan the steps (in chat, short). Each step = one atomic commit.
2. Implement → unit/integration tests → **type-check** → lint → tests. Fix until green.
3. Schema change → migration + update `docs/DATABASE.md` (mermaid + DBML) + `sh .agents/hooks/db-schema-check.sh`.
4. UI → DESIGN tokens, 4 states, `ui-slop-check.sh`, copywriting check.
5. Critical flow → Playwright E2E; run it (`pnpm e2e` or the project's E2E command) and make it pass.
6. Full verify command passes → update `docs/PROGRESS.md` (tick + log) → commit.
7. Next story. Never start a new story with a red verify.

### Something unclear in the middle?
Do NOT stop and do NOT silently guess. Instead:
1. Pick the **safest, most reversible** option (the one easiest to change later; keep it isolated in one place).
2. Mark it in code: `// ASSUMPTION(Q3): <what you assumed>` (comment syntax of the language).
3. Add it to `docs/PROGRESS.md` → "Open questions (marathon)":
   `Q3 — <question> | assumed: <choice> | where: <file> | options: A/B/C`.
4. Continue.

### A request in the backlog goes against a recorded decision?
Do not apply it on your own (AGENTS.md rule 12). Keep the current plan, log it in "Open questions (marathon)" as
`CHANGE(Q4) — awalnya: <old> (sumber) | diminta: <new> | dampak: <impact>`, and continue with other stories. It is
asked with the Change check format in `.agents/knowledge/grill-me.md` when the user is back.

### Hard stops (even in a marathon)
Stop immediately and ask (grill format) only for the `AGENTS.md` §4 STOP list: deleting data/files, destructive
migrations on real data, force push, production / real credentials, paid services, security-sensitive auth/payment
changes not covered by the up-front answers — and the Stuck rule (same problem survived 2 fix attempts: revert the
experiment, mark the story blocked with what you learned, move to the next independent story).

## Phase 3 — Finish line
1. Run everything once more: full verify (format, lint, type-check, unit/integration) + full E2E suite. Report real output.
2. Re-read `AGENTS.md` §5 Definition of Done for the whole marathon.
3. Report per `AGENTS.md` §6, plus: stories done / blocked, and the list of open questions with the assumption taken.

## When the user says "lanjut" / "gaskan" / "next"
1. If "Open questions (marathon)" is not empty → **grill those first** (grill-me format, with your assumption as one of the
   options, pros/cons, recommendation). Apply the answers: keep or change the code, remove the `ASSUMPTION` markers,
   commit (`fix:` / `refactor:`), update docs.
2. Then continue with the next stories (Phase 2), or start a new marathon target if the backlog is done.
