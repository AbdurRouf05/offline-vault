# Open-source research & reuse

Before building, look for open-source projects that already solve part of the problem. Reuse ideas always;
reuse code only when the license and quality allow it; adapt everything to our rules.

## 1. Search

- Web/GitHub search tools if available. Otherwise GitHub CLI (flags verified with `gh search repos --help`):
  ```
  gh search repos "<keywords>" --sort stars --limit 20 --json fullName,description,stargazersCount,pushedAt,license,language,url
  gh search repos "<keywords>" --language typescript --stars ">100" --updated ">2025-01-01" --limit 20
  ```
- Search in English AND the user's language; try synonyms ("pos", "point of sale", "kasir"; "inventory", "stock").
- Also look at: GitHub topics, "awesome-<topic>" lists, self-hosted alternatives lists, and libraries for single features
  (e.g. a calendar, a PDF generator, a barcode scanner) — a library is often better than copying an app.
- No tool access → give the user 3–5 ready search queries/links and ask them to paste what they find.

## 2. Verify (mandatory — AI often invents repo names)

For every repo you mention: open it (fetch the page / `gh repo view <owner/repo>`) and confirm it exists, read the README,
the LICENSE file, last commit date, and skim the folder structure. Anything not verified is labeled "belum dicek".

## 3. Evaluate

| Signal | Good | Warning |
|---|---|---|
| License | MIT, Apache-2.0, BSD, ISC (copy allowed with notice) | GPL/AGPL/LGPL (copying code binds your project to that license), no license (all rights reserved), "source-available"/non-commercial |
| Activity | Commits in the last ~12 months, issues answered | Archived, years without commits, many unanswered issues |
| Fit | Same or compatible stack, similar scale | Very different stack, huge monolith for a small need |
| Quality | Tests, types, clear structure, CI, docs | No tests, giant files, secrets in repo, outdated deps with known vulnerabilities |
| Size | Small enough to understand | You'd need weeks just to understand it |

Stars show popularity, not quality. Read code before trusting it.

## 4. Adoption modes (pick per repo, per feature)

| Mode | When | How |
|---|---|---|
| **Inspiration** | Any license; good ideas but code doesn't fit | Study features, flows, data model, UX. Write our own code. Never copy code from GPL/no-license repos into a non-GPL project |
| **Use as dependency** | It's a maintained library | `pnpm add` / `composer require` / `uv add`. Wrap it in one module (`architecture.md`). Prefer this over copying |
| **Extract module** | Permissive license, a self-contained piece we need | Copy only the needed files; keep the license header; add an entry to `THIRD_PARTY_NOTICES.md` (repo, commit hash, license); refactor to our structure, naming, and DESIGN.md; add tests |
| **Fork as base** | Permissive (or user accepts the license), stack fits, quality is decent, covers most of the MVP | Record an ADR. Clone, then run `wf-onboard` (it is now an existing codebase), install the kit, fix gates first, then refactor toward our rules step by step. Keep `upstream` remote only if you plan to pull updates |

Also an option: **don't build** — if an existing product/self-hosted app already does it well, tell the user honestly.

## 5. Feature-source matrix

Decide per feature where it comes from and what we change:

| Feature | Source | Mode | Changes to fit our rules |
|---|---|---|---|
| Product catalog | repo A | Inspiration | Our data model (DATABASE.md), DESIGN.md UI |
| Barcode scan | library X | Dependency | Wrapped in `integrations/barcode` |
| Sales report | — | Build | — |

## 6. Rules when reusing code

- Never copy code you don't understand. Read it, then adapt it.
- Copied code meets the same bar as our code: modular boundaries, types, tests, security checklist, no AI-slop UI.
- Check copied dependencies for known vulnerabilities (`pnpm audit`, etc.).
- Keep attribution and license notices. When unsure about a license, tell the user — don't decide silently.
