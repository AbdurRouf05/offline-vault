# Documentation

Docs exist so that **any** person or AI can continue the work tomorrow with zero chat history.
Write for a reader who is smart but knows nothing about this project.

## The project memory files

| File | Purpose | Update when |
|---|---|---|
| `docs/IDEA.md` | Notes of the early discussion (`wf-brainstorm`): story, decisions, parked ideas, coverage. History once the PRD exists. | Every brainstorm round |
| `docs/research/oss-repos.md` | Verified open-source shortlist, adoption mode per repo, feature-source matrix, license obligations. | Repo research or reuse decisions |
| `docs/PRD.md` | Product: problem, goals, users, scope, user stories (= functional requirements), NFRs, key flows. Replaces BRD/SRS/user-story docs. | Scope or behavior changes |
| `docs/DESIGN.md` | Design system: tokens, type, spacing, components, icons, voice & glossary. | Look, components, or terminology change |
| `docs/DATABASE.md` | Schema as mermaid diagram + DBML (identical content, checked by `db-schema-check.sh`), table notes, migration log. | Every schema/migration change (same commit) |
| `docs/PROJECT.md` | Technical: stack, architecture, module rules, data model, commands, conventions. | Stack, structure, commands, or conventions change |
| `docs/PROGRESS.md` | Current state, backlog, next steps, short log. The "save game". | **After every completed step** |
| `docs/HANDOFF.md` | Snapshot for the next session or model: where work stopped, what is half-done, next 3 steps, user preferences, gotchas. Overwritten, max ~150 lines (`wf-handoff`). | **After every finished task and when the chat gets long** |
| `docs/CHATLOG.md` | Every user message verbatim + 1-2 line AI summary. Append-only history (`node .agents/scripts/chatlog.mjs`). | **Every turn** |
| `docs/decisions/NNNN-title.md` | ADRs — why a significant decision was made. Never rewritten; superseded by a new ADR. | Significant decision made |
| `README.md` | How to set up, run, test, deploy. For humans arriving at the repo. | Setup/run/env/deploy changes |
| `CHANGELOG.md` | User-visible changes per version (Keep a Changelog format). | User-facing change merged |
| `.env.example` | Every env var with placeholder + comment. | New/removed env var |

Templates live in `.agents/templates/`.

## What counts as a "significant decision" (→ ADR)

- Choosing/changing a framework, database, auth method, hosting, or major library.
- An architectural pattern (e.g. multi-tenancy approach, sync strategy, caching strategy).
- A trade-off you'd want explained in 6 months ("why didn't we just use X?").
- Deviating from this kit's defaults.

Not ADR-worthy: naming a variable, choosing between two equivalent small utilities.

## PROGRESS.md rules

- **Current state** reflects reality right now (what works, what's broken, what's in progress).
- **Next steps** are concrete and ordered — the next AI should be able to start immediately.
- **Log**: one line per completed step, newest first: `YYYY-MM-DD — feat: … / fix: … / chore: …`.
- Keep it short. Move old log entries to `docs/progress-archive.md` when the log exceeds ~50 lines.

## Code-level docs

- Public functions/modules with non-obvious behavior: a short docstring (purpose, params with units, return, errors thrown).
- Comments explain *why*. If the *what* needs a comment, rename or restructure first.
- API: OpenAPI spec (generated from code where possible) when there are external consumers.
- Complex flows: a mermaid diagram in `docs/PROJECT.md` beats paragraphs.

## Writing style

These rules are for project docs read by developers and AIs (PROJECT, PROGRESS, HANDOFF, README). Documents for
other people (reports, proposals, papers, letters, slides) follow `.agents/knowledge/writing.md` instead:
paragraphs for explanations, lists only for real lists.

- Short sentences. Lists and tables over paragraphs.
- Exact commands in code blocks, copy-pasteable.
- No marketing language, no filler. State facts.
- Dates as `YYYY-MM-DD`.
