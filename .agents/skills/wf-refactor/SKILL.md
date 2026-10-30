---
name: wf-refactor
description: Restructure or clean up code without changing its behavior - lock behavior with tests first, then change in small verified steps. Use for cleanup, splitting big files, renaming, removing duplication, or improving structure.
---

# wf-refactor — Change structure, never behavior

## Rules
- **Behavior must stay identical.** No new features, no bug fixes mixed in. Found a bug? Note it, fix it separately (`wf-bugfix`).
- Every step is small and leaves the code working. Verify after each step.
- Refactor only with a clear reason: hard to read, duplicated logic, file too large, blocking an upcoming feature.
  "It could be more elegant" is not enough.

## Step 1 — Scope
State: what code, what is wrong with it now, what the target looks like, and why it matters.
If it touches more than ~10 files or a public API/DB schema → show the plan and wait for the user's OK.

## Step 2 — Lock behavior
1. Check test coverage of the code you will change.
2. If coverage is weak, first write **characterization tests**: tests that record what the code does NOW
   (even if it looks odd). Commit them separately: `test: characterize <area> before refactor`.
3. Run verify. It must pass before you start.

## Step 3 — Refactor in small steps
Typical safe steps (one at a time, verify after each):
- Rename for clarity (use the editor/IDE rename or search all usages).
- Extract function / component / module.
- Move code to the right module (per `.agents/knowledge/architecture.md`).
- Replace duplication with one shared implementation.
- Delete dead code (search for usages first; confirm it is truly unused, including dynamic usages, routes, and config).

Commit after each meaningful step: `refactor(<scope>): <what>`.

## Step 4 — Verify & report
1. Full verify passes; characterization tests unchanged and passing.
2. Diff review: confirm no behavior change slipped in (changed conditions, defaults, error handling, ordering).
3. Update `docs/PROJECT.md` if structure/conventions changed. Log in `docs/PROGRESS.md`. Report per `AGENTS.md` §6.

## Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item that applies. Report per `AGENTS.md` §6.
