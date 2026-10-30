---
name: wf-code-review
description: Review code, a diff, a branch, or a PR for correctness, security, tests, and maintainability, and report ranked findings with file:line and concrete fixes. Use when asked to review, check, or audit the quality of code.
---

# wf-code-review — Find real problems, not nitpicks

## Step 1 — Get the target
- Uncommitted changes: `git diff` and `git diff --staged`. Branch: `git diff <base>...HEAD`. PR: fetch its diff.
- Read `docs/PROJECT.md` for conventions. Read surrounding code of each change, not just the changed lines —
  most real bugs are in how the change interacts with existing code.

## Step 2 — Review in this priority order
1. **Correctness** — Does it do what it claims? Edge cases: empty/null, zero, negative, very large, duplicates,
   unicode, timezones, concurrency/double-submit, partial failure, retries. Off-by-one. Wrong condition. Unhandled errors.
2. **Security** — `.agents/knowledge/security.md`: injection, missing authz check, secrets, unsafe file handling,
   XSS, SSRF, mass assignment, sensitive data in logs/responses.
3. **Data safety** — Migrations reversible? Can it lose or corrupt data? Transactions where multiple writes must succeed together?
4. **Tests** — Is new behavior tested, including an unhappy path? Do tests assert meaningful things?
5. **Design & simplicity** — Unnecessary abstraction, duplication of an existing helper, wrong layer (business logic in UI/controller),
   leaky module boundaries.
6. **Performance** — Only obvious issues: N+1 queries, unbounded loops/lists, missing pagination, work inside hot loops,
   large payloads.
7. **Readability** — Unclear names, misleading comments, dead code.

Skip anything a formatter/linter already enforces.

## Step 3 — Verify each finding
Before reporting, re-read the code and confirm the issue is real (trace the actual path, check callers,
check if it's handled elsewhere). Drop findings you can't support. If unsure, mark it as a question.

## Step 4 — Report
Ranked, most severe first:
```
[KRITIS|TINGGI|SEDANG|RENDAH] path/to/file.ext:LINE — <problem in one sentence>
  Skenario: <concrete input/state → wrong result>
  Saran: <specific fix>
```
End with: overall verdict (siap merge / perlu perbaikan / perlu diskusi) and anything good worth keeping.
Do not modify code unless the user asks you to apply fixes.
