---
name: wf-onboard
description: Adopt the Workflow Kit in an existing codebase. Explores the code, detects the stack and commands, writes docs/PROJECT.md and docs/PROGRESS.md, and finds missing quality gates — without changing app behavior. Use when code exists but docs/PROJECT.md does not.
---

# wf-onboard — Understand an existing project before touching it

Goal: create accurate project memory (`docs/`) from what is ACTUALLY in the code. **Do not refactor or "improve" anything in this skill.**

## Step 1 — Explore (read-only)

1. List the top-level structure (2–3 levels deep). Skip `node_modules`, `vendor`, `.venv`, `build`, `dist`, `.git`.
2. Read the manifest files that exist: `package.json`, `composer.json`, `pyproject.toml`/`requirements.txt`,
   `pubspec.yaml`, `go.mod`, `Cargo.toml`, `*.csproj`, `build.gradle*`, `Dockerfile`, `docker-compose.yml`, CI files.
3. Read the existing `README.md` and any docs.
4. Identify: language(s), framework(s), database, entry points, main modules, test setup, lint/format setup, deploy target.
5. Read 2–3 representative files (one route/controller/screen, one model/data file, one test) to learn the code style.

## Step 2 — Run it

1. Find the install / dev / build / test commands (manifest scripts, README, Makefile, CI file).
2. Run install and the test command. Record what happens — passing, failing, or "no tests".
3. If something fails, **do not fix it now**. Record it under "Known issues".

## Step 3 — Write project memory

1. `docs/PROJECT.md` from `.agents/templates/PROJECT.md`. Fill only what you verified. Mark unknowns as `UNKNOWN — ask user`.
2. `docs/PROGRESS.md` from `.agents/templates/PROGRESS.md`. Current state + Known issues.
3. `docs/decisions/0000-existing-stack.md`: an ADR describing the stack as found (status: Accepted, context: "inherited").
4. `docs/PRD.md` (short): reverse-engineer what the product does — users, main features as user stories, known gaps.
   Mark guesses as `UNKNOWN — ask user`.
5. Has a UI → `docs/DESIGN.md`: record the colors, fonts, spacing, and components actually in use (don't redesign).
   Note slop patterns found as "to fix later", not as the standard.
6. Git repo → `sh .agents/hooks/install-hooks.sh` (it never overwrites existing hooks).

## Step 4 — Gap report

Compare against `.agents/knowledge/quality-gates.md` and report to the user:

```
Hasil onboarding:
- Stack: …
- Perintah: dev=…, test=…, build=…
- Kondisi tes: … (lulus / gagal N / tidak ada)
- Gate yang belum ada: formatter / linter / type-check / tests / verify command / pre-commit / CI / secret scan
- Risiko yang terlihat: … (e.g. secrets in repo, no auth on routes, outdated deps)
- Rekomendasi urutan: 1) … 2) … 3) …
```

CHECKPOINT: ask which gaps to fix. Adding gates is a separate task. If tests are missing, add a verify command first
(even if it only runs lint + build), then add tests around the areas most likely to change.

## Rules

- Existing conventions win over the kit's preferences unless the user agrees to change them. Record conventions in
  `docs/PROJECT.md` → Conventions.
- Never run destructive commands (DB reset, migrations on real data, deleting files) during onboarding.
- If secrets are found in the repo, tell the user immediately (they must be rotated, not just deleted).

## Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item that applies. Report per `AGENTS.md` §6.
