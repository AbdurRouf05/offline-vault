---
name: wf-feature
description: Add or change a feature safely - link it to a user story, clarify acceptance criteria, locate code, plan, implement in small verified steps with tests and atomic commits, security and UI checks, self-review, and docs. Use for any new behavior or change in behavior that is bigger than a tiny edit.
---

# wf-feature — Build one feature, properly

## Step 1 — Context
1. Read `docs/PROJECT.md` (stack, architecture, module rules, commands) and `docs/PROGRESS.md`.
2. Read `docs/PRD.md`: find the user story (US-xx) this feature implements. None exists → add one to the PRD first
   (ask the user to confirm if it changes scope).
3. Feature touches UI or visible text → read `docs/DESIGN.md`, `.agents/knowledge/ui-ux.md`, `.agents/knowledge/copywriting.md`.

## Step 2 — Acceptance criteria
Use the story's criteria from the PRD, or write 2–6 testable ones:
```
- Given <situation>, when <action>, then <expected result>.
```
Include at least one **unhappy path** (invalid input, no permission, empty state, network/DB failure).
Anything unclear or costly to undo → grill the user (`.agents/knowledge/grill-me.md`). Don't guess.

## Step 3 — Locate
1. Search the codebase for related code: similar features, existing helpers, models, components, routes.
2. Read every file you plan to change. Note the patterns they use — you will follow them.
3. **Reuse before create.** Decide which feature module owns the new code (`.agents/knowledge/code-quality.md` → Modularity).

## Step 4 — Plan
Fill `.agents/templates/PLAN.md` (in chat; save to `docs/plans/` only if the plan is large).
- Files to create/change, steps in order, tests to add, risks.
- **Each step = one atomic commit**: small, complete, passes verify on its own (`.agents/knowledge/git.md`).
- More than ~6 steps or ~8 files → split into smaller features, each shippable alone.
- Data model change? Plan the migration, say whether it is reversible, and update `docs/DATABASE.md` (mermaid + DBML).
- New dependency? Say why existing ones are not enough. Ask before adding big ones.

CHECKPOINT: show the plan. Small, clear features may proceed after showing it; anything touching data model,
auth, payments, or public APIs waits for the user's OK.

## Step 5 — Implement (loop per step)
For each plan step:
1. Make the change. Follow existing style and module boundaries.
2. Write/update tests for this step (`.agents/knowledge/testing.md`). Prefer test-first for logic.
3. UI in this step → use DESIGN.md tokens and components only; real-looking data; handle loading/empty/error/success.
4. Run verify. Add a log line to `docs/PROGRESS.md`. Commit (`feat(scope): ...`). Then next step.
5. Same failure twice → Stuck rule in `AGENTS.md` §4.

## Step 6 — Security pass
Feature handles user input, auth, roles, files, money, personal data, or external calls →
go through the matching sections of `.agents/knowledge/security.md` and fix gaps.

## Step 7 — Verify for real
1. Full verify command passes (`docs/PROJECT.md` → Commands).
2. Exercise the feature: run the app / call the endpoint / run the script; check each acceptance criterion.
3. UI: check the 4 states, ~375px and desktop width, long real data; run `sh .agents/hooks/ui-slop-check.sh <files>`;
   read every new string against `copywriting.md`.
4. Critical user flow (login, checkout, payment, main create/edit flow) → add or update a Playwright E2E test.

## Step 8 — Self-review
Read the full diff of the feature top to bottom as a strict reviewer, using the checklist in
`.agents/knowledge/code-quality.md`. Fix what you find in a new commit. Remove debug leftovers.

## Step 9 — Docs
1. `docs/PROGRESS.md`: tick the backlog item, set Next steps.
2. PRD if behavior/scope changed. ADR for significant decisions. README/CHANGELOG if user-facing. `.env.example` if new env vars.

## Step 10 — Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item. Report per `AGENTS.md` §6, listing each acceptance
criterion as [OK] or [GAGAL].
