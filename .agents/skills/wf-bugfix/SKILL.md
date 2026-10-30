---
name: wf-bugfix
description: Fix a bug, error, crash, or wrong behavior by reproducing it first, finding the root cause with evidence, applying a minimal fix, and adding a regression test. Use whenever something is broken or behaves unexpectedly.
---

# wf-bugfix — Evidence first, then fix

The #1 failure of AI fixes: changing code based on a guess. **No fix without a reproduced bug and an identified cause.**

## Step 1 — Capture
Write down (in chat):
- **Expected** behavior vs **actual** behavior.
- The **exact** error message and stack trace — read it fully, including the first line of YOUR code in the trace.
- Where/when it happens (which page, input, environment, since when). Ask the user if missing and you can't find it.

## Step 2 — Reproduce
1. Reproduce it yourself: run the command / test / request that triggers it.
2. Best: write a **failing automated test** that shows the bug. Second best: exact manual reproduction steps.
3. Can't reproduce? Don't fix blindly. Add targeted logging around the suspected area, ask the user for more details
   (inputs, logs, environment), and stop here until you can.

## Step 3 — Find the root cause
1. List up to 3 hypotheses, each with "how to confirm or rule out".
2. Test the cheapest hypothesis first: read the code path, add temporary logs/prints, inspect actual values.
3. Trace back to the **origin** of the bad value/state — not just where it crashes.
   Ask "why?" until you reach the real cause (e.g. crash on `null` → why null? → API returns empty list on timeout → why?…).
4. Check if the same mistake exists in other places (search for the pattern).
5. If the library/framework is involved, check its real behavior (installed source, docs, changelog) — don't assume.

## Step 4 — Fix
1. Minimal change that fixes the **cause**. No unrelated refactors in the same change.
2. Never "fix" by: deleting/skipping the failing test, catching and ignoring the error, adding `any`/`@ts-ignore`/`# type: ignore`,
   adding arbitrary sleeps/retries to hide a race, or special-casing the one input from the bug report.
3. Remove all temporary logs.

## Step 5 — Verify
1. The failing test from Step 2 now passes.
2. The full verify command passes (no new failures elsewhere).
3. Re-run the original reproduction steps manually if it was user-visible.

## Step 6 — Record
1. `docs/PROGRESS.md` → Log: `fix: <symptom> — cause: <root cause> — fix: <what changed>`.
2. Commit: `fix(<scope>): <what was wrong>`.
3. Report using `AGENTS.md` §6, including the root cause in one sentence.

## Stuck rule
2 failed fix attempts → stop. Revert experiments (`git stash` or `git checkout -- <files>` after confirming with user if
there are other uncommitted changes). Write: what you know for sure, what you ruled out, the remaining hypotheses, and
what information would settle it. Ask the user how to proceed.

## Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item that applies. Report per `AGENTS.md` §6.
