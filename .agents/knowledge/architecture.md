# Architecture

## Core principles

1. **Start as a modular monolith.** One deployable app, internally split into feature modules with clear boundaries.
   Split into services only when a module has a proven, different scaling/deploy/team need. Record that as an ADR.
2. **Organize by feature, not by file type.** `features/orders/{routes,service,repo,schema,tests}` beats
   `controllers/ models/ services/` with 40 files each. (Follow the framework's convention when it is strong, e.g. Laravel's
   `app/Models`, but group business logic by domain inside it.)
3. **Dependencies point inward.** UI/HTTP → application logic → domain rules. Infrastructure (DB, HTTP clients, files, email)
   is called through a small module the logic owns. Business rules must not import UI or framework request objects.
4. **One home for each external service.** Wrap each third-party API (payments, email, AI, storage) in a single module
   (`integrations/midtrans.ts`). The rest of the app calls that module, never the SDK directly. Easy to mock, easy to replace.
5. **Config from environment.** All secrets and environment-specific values come from env vars, validated at startup
   (fail fast with a clear message if missing). One `config` module reads them; nothing else touches `process.env`/`os.environ`.
6. **Thin entry points.** Controllers/route handlers/screens: parse input → call logic → return output. No business logic there.
7. **Size limits as smell detectors.** File > ~300 lines or function > ~50 lines or > 3 levels of nesting → probably split.

## Layers (typical server app)

```
HTTP / UI / CLI layer     → validates input, maps to/from DTOs, handles auth context
Application / service     → use cases: "create order", "approve invoice" — orchestrates, owns transactions
Domain                    → pure rules and types (no I/O) — easiest to unit test
Infrastructure            → DB repositories, external API clients, file storage, queues, email
```
For S-tier projects, merging application+domain is fine. Keep I/O at the edges anyway.

## The 13 concerns (checklist)

People sometimes talk about "13 layers of an application". That is not a standard term — but the useful idea behind it is a
checklist of concerns every real app must decide on. Group them into the 4 layers above:

| Layer | Concern | Decide |
|---|---|---|
| UI | 1. Presentation | Components, DESIGN.md tokens, 4 states |
| UI | 2. Routing / navigation | URL or screen structure, guarded routes |
| UI | 3. Client state | Server cache vs local UI state, forms |
| Entry | 4. Validation | Schema at every boundary (server always) |
| Entry | 5. Transport / controllers | REST/RPC/actions, thin handlers, error format |
| Entry | 6. Authentication | Who is this? Sessions/tokens, provider |
| Entry | 7. Authorization | Can they do this to this resource? Checked server-side |
| Application | 8. Business logic | Use cases + pure domain rules |
| Infrastructure | 9. Data access | Repositories / ORM, transactions |
| Infrastructure | 10. Database & migrations | Schema, indexes, reversible migrations, backups |
| Infrastructure | 11. Integrations | One wrapper module per external service |
| Infrastructure | 12. Background jobs | Queues, scheduled tasks, retries, idempotency |
| Cross-cutting | 13. Config, logging, errors, caching, observability | Env validation, structured logs, error tracking |

For tier S, many rows are "not needed" — write that down instead of building them. For tier M/L, record each decision in
`docs/PROJECT.md` → Architecture.

## Data model rules

- Schema changes **only via migrations**, committed to git. Never edit the production DB by hand.
- Enforce integrity in the database: NOT NULL, foreign keys, UNIQUE, CHECK — not only in app code.
- Every table: primary key, `created_at`, `updated_at`. Store times in **UTC**; convert at display.
- Money: integer minor units (cents/rupiah) or DECIMAL — **never float**. Store currency if more than one.
- Soft delete only when there's a real requirement (audit, undo). Otherwise delete.
- Index columns used in WHERE/JOIN/ORDER BY of frequent queries. Paginate every list endpoint.
- Multiple writes that must succeed together → one transaction.

## API design (HTTP)

- REST-style resources: `GET /orders`, `POST /orders`, `GET /orders/{id}`, `PATCH /orders/{id}`, `DELETE /orders/{id}`.
- Correct status codes: 200/201/204, 400 (bad input), 401 (not logged in), 403 (not allowed), 404, 409 (conflict), 422 (validation), 500.
- One consistent error shape, e.g. `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "fields": { "email": "..." } } }`.
- Validate request bodies with a schema library (Zod, Pydantic, Laravel Form Requests, etc.).
- Pagination (`?page=&limit=` or cursor) with a max limit. Never return unbounded lists.
- Document with OpenAPI when the API has external consumers (or a separate mobile/desktop client).
- Breaking changes to a public API → version (`/v2`) or deprecate gradually.

## Frontend / client apps

- Components small and focused; separate **data fetching/state** from **presentational** components.
- Server state via a data library (TanStack Query, SWR, Riverpod, etc.) — not hand-rolled global stores.
- Global client state only for truly global things (auth user, theme). Prefer local state.
- Every screen that loads data handles: loading, empty, error, success. See `ui-ux.md`.
- Never trust the client: all validation and permission checks are repeated on the server.

## Error handling & logging

- Fail loudly in development, gracefully in production. Never swallow exceptions silently.
- Catch errors at boundaries (request handler, job runner, UI error boundary), log with context, return a safe message.
- Structured logs (JSON in production) with request id / user id. **Never log secrets, passwords, tokens, or full card/personal data.**
- Expected failures (validation, not found, payment declined) are normal results, not crashes.

## Example structures

**Next.js (TS) web app**
```
src/
  app/                 # routes (thin): pages, layouts, route handlers
  features/
    orders/            # components/, actions.ts, service.ts, repo.ts, schema.ts, orders.test.ts
    auth/
  lib/                 # shared utilities (db client, config, logger)
  integrations/        # one file/folder per external service
  components/ui/       # shared presentational components
```

**Laravel**
```
app/
  Http/Controllers/    # thin
  Http/Requests/       # validation
  Models/
  Actions/ or Services/<Domain>/   # business logic per domain
  Integrations/        # external API wrappers
database/migrations/
tests/Feature/  tests/Unit/
```

**Flutter**
```
lib/
  core/                # config, router, theme, shared widgets, error handling
  features/
    orders/
      data/            # repositories, API/DB sources, models
      domain/          # entities, business rules (optional for S tier)
      presentation/    # screens, widgets, state (providers/blocs)
test/
```

**Tauri desktop**
```
src/                   # web UI (features/ like the web example)
src-tauri/src/
  commands/            # thin #[tauri::command] handlers
  services/            # logic
  db/                  # SQLite access
```

**Python script / CLI**
```
script.py              # S tier: single file, main() + small functions, inline deps
# M tier:
src/<pkg>/cli.py  core.py  io.py
tests/
pyproject.toml
```
