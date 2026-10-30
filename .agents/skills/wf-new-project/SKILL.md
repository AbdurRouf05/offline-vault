---
name: wf-new-project
description: Start a new project from zero (web app, mobile app, desktop app, script, CLI, bot, API, anything). Runs discovery, tech stack selection, architecture, scaffolding, quality gates and docs before any feature code. Use when the user wants to build something new or the folder is empty.
---

# wf-new-project — From idea to a verified skeleton

Goal: by the end, the project has a confirmed scope, a justified stack, a clean structure, working quality gates,
and docs — so every later feature is built on solid ground. **Do not write feature code before Phase 5 passes.**

Do the phases in order. Each phase ends with a CHECKPOINT: show the result and wait for the user's OK.
After each phase, update `docs/PROGRESS.md` (create it from `.agents/templates/PROGRESS.md` in Phase 1).

---

## Phase 1 — Discovery (understand before choosing anything)

Came from `wf-brainstorm` (`docs/IDEA.md` + `docs/PRD.md` exist)? Read them, confirm the PRD summary with the user,
and go to Phase 2. Use `docs/research/oss-repos.md` decisions in Phase 2–4 (libraries, fork base, extracted modules).
Idea still vague and the user wants to talk it through → switch to `wf-brainstorm`.

Grill the user (`.agents/knowledge/grill-me.md`): only questions whose answers you don't already know, in rounds of
max 4, each with options, a recommendation, and pros/cons.

1. **What** is it, in one sentence? What problem does it solve?
2. **Who** uses it? (just me / my team / public users / clients) and roughly **how many**?
3. **Platform(s):** web, mobile (Android/iOS), desktop (Windows/macOS/Linux), CLI/script, bot, API, other?
4. **Core features** for the first version (MVP). Ask for a list; then suggest what to cut.
5. **Data:** what is stored? Sensitive data (passwords, payments, personal data)? Must it work **offline**?
6. **Integrations:** login/auth, payments, email/WA/notifications, maps, AI/LLM, file uploads, third-party APIs?
7. **Constraints:** deadline, budget for hosting, where it will run/deploy, languages the user already knows or prefers,
   must it be fast/light (low-end devices, cheap VPS)?

Then:
- Classify **size tier** using `.agents/knowledge/stack-selection.md` → "Step 2: size tier".
- Create `docs/PRD.md` from `.agents/templates/PRD.md`: problem, goals + non-goals, target users, scope
  (MVP / later / out), user stories with acceptance criteria (= functional requirements), NFRs, key flows (mermaid).
  Keep it short — a PRD nobody reads is waste. Unknowns are written as open questions, not invented.
- Write MVP stories as a checklist in `docs/PROGRESS.md` → Backlog, ordered by dependency (foundation first).

CHECKPOINT: show the PRD summary (MVP stories + what is explicitly out of scope). Wait for confirmation.

## Phase 2 — Tech stack selection

Follow `.agents/knowledge/stack-selection.md` exactly (platform → size tier → feature needs → pick).

Present to the user:
```
Rekomendasi stack: <stack>
Kenapa: <3–5 reasons tied to THEIR requirements, not generic praise>
Trade-off: <what we give up>
Alternatif: <1 alternative + when it would be better>
```
- Prefer what the user already knows when it is a reasonable fit (speed of delivery matters more than "best").
- Get the **current stable versions** from the package manager / official generator. Never write versions from memory.

After confirmation: write `docs/decisions/0001-tech-stack.md` (template `.agents/templates/ADR.md`) and fill
`docs/PROJECT.md` → Stack.

CHECKPOINT: Wait for confirmation of the stack.

## Phase 3 — Architecture

Follow `.agents/knowledge/architecture.md`.

Produce, in `docs/PROJECT.md` → Architecture:
1. **Pattern** chosen for this size tier and why (1–2 lines).
2. **Folder structure** (tree, top 2–3 levels) organized by feature/module.
3. **Data model:** create `docs/DATABASE.md` from `.agents/templates/DATABASE.md` — mermaid diagram + DBML with the
   same tables/columns/relations; run `sh .agents/hooks/db-schema-check.sh`. Tell the user how to view it visually.
4. **Key flows:** the 2–4 most important user flows, step by step (e.g. sign up → verify → first action).
5. **External boundaries:** which external services, and the single module that wraps each.
6. **Security notes:** where auth happens, who can do what (roles), what data is sensitive.

CHECKPOINT: Show it. Wait for confirmation.

## Phase 3b — Design system (only if the project has a UI)

Follow skill `wf-design` → "Create DESIGN.md". Personality, color tokens (neutral + one accent, light default),
type scale, spacing, components, voice & glossary. Output: `docs/DESIGN.md`.

CHECKPOINT: show the design summary. Wait for confirmation.

## Phase 4 — Scaffold

1. Use the **official generator** of the chosen framework (e.g. `pnpm create vite`, `pnpm create next-app`,
   `pnpm create tauri-app`, `composer create-project laravel/laravel`, `flutter create`, `uv init`, `cargo new`,
   `go mod init`). JS/TS always with pnpm. Run `--help` first if unsure of flags. Do not hand-write what a generator produces.
2. Create the folder structure from Phase 3 (empty modules are fine; add a short README or index only where useful).
3. `git init` (if not already a repo). Add a proper `.gitignore` for the stack (include `.env`, build outputs, OS files).
4. Create `.env.example` listing every needed variable with a fake placeholder and a comment. Real `.env` is never committed.
5. Make the app run: start it and confirm it actually starts (dev server responds / app window opens / script runs).

## Phase 5 — Quality gates (the most important phase)

Follow `.agents/knowledge/quality-gates.md` for the chosen stack:

1. Formatter + linter configured.
2. Type checking (where the language supports it), in strict mode.
3. Test runner with **one real passing test**.
4. **One `verify` command** that runs format-check + lint + type-check + tests. Write it in `docs/PROJECT.md` → Commands.
5. Kit hooks: `sh .agents/hooks/install-hooks.sh` (anti-slop UI check, secret scan, commit message format,
   PROGRESS.md reminder). Add format + lint to the pre-commit (lefthook example in `quality-gates.md`).
6. Module boundary + dead-code tool for tier M/L (`quality-gates.md` → Boundaries).
7. UI app → Playwright installed with one smoke E2E test (`testing.md` → "E2E with Playwright").
8. CI workflow (e.g. `.github/workflows/ci.yml`) running the verify command on push/PR — if the project will use GitHub.

Run the verify command. **It must pass before moving on.** Show the output summary.

## Phase 6 — Docs

1. `README.md` from `.agents/templates/README.md` (what, requirements, setup, run, test, env vars, deploy).
2. `CHANGELOG.md` from `.agents/templates/CHANGELOG.md`.
3. `docs/PROJECT.md` → Commands complete (install, dev, build, test, verify, lint, format).
4. `docs/PROGRESS.md` updated: Phase 1–6 done, Backlog ready, Next step = first backlog item.
5. First commit: `chore: initial project scaffold with quality gates` (see `.agents/knowledge/git.md`).

## Phase 7 — Build the MVP

- First feature = **walking skeleton**: the thinnest end-to-end slice that touches every layer
  (e.g. UI → API → DB → back to UI for one simple entity). This proves the architecture works.
- Then build each backlog item with skill `wf-feature`, one at a time, in order. Atomic commits throughout.
- After each phase and at the end: re-read `AGENTS.md` §5 and report per §6.

---

## Common mistakes to avoid

- Picking a stack before knowing platform, size, and features.
- Writing features before the verify command exists and passes.
- Microservices, Kubernetes, event buses, or multiple databases for an MVP. Start as a modular monolith.
- Inventing package versions or framework APIs from memory.
- Building every feature the user mentioned. MVP = the smallest set that delivers the core value.
