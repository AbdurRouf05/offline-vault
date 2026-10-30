# Tech Stack Selection

Pick the stack from **requirements**, not from hype or habit. Work through the steps in order.
The goal is the stack that delivers THIS project fastest and safely, and can grow as far as the project realistically will.

> Ecosystems change. Before adopting any library/framework, check it is maintained (release in the last ~12 months,
> active issues, real docs). Get versions from the package manager or official generator — never from memory.

---

## Step 0 — Hard constraints first

1. **Existing project?** Keep its stack. Changing stacks needs a very strong reason and the user's approval.
2. **What does the user know?** A familiar "good enough" stack beats an unfamiliar "best" stack. Ask if unknown.
3. **Where must it run?** (shared hosting with only PHP, cheap VPS, user's Windows PC, Play Store, offline field devices…)
4. **Budget**: free tier only? Avoid choices that force paid services.

## Step 1 — Platform

Web · Mobile · Desktop · Script/CLI/automation · Bot · API only · Other (extension, game, IoT, AI app).
Several platforms? Choose the backend once and share it (one API serves web + mobile + desktop).

## Step 2 — Size tier

| Tier | Signals |
|---|---|
| **S — Small** | Personal/internal tool, 1–5 features, few users, simple or no stored data, no complex roles. Script, landing page, small utility. |
| **M — Medium** | Real users, login, CRUD on several entities, a few integrations (payments, email, uploads), 1–2 devs, up to tens of thousands of users. Most apps live here. |
| **L — Large / complex** | Many modules and roles, multi-tenant, high traffic or heavy compute, realtime at scale, strict performance/resource limits, long-lived product, several devs. |

When between tiers, choose the **lower** tier's stack if it can grow into the higher one (most M stacks scale fine).
For L: prioritize **fast (runtime + dev speed), light (low RAM/CPU), flexible (easy to extend/replace parts)**.

## Step 3 — Feature needs that change the choice

| Need | Implication |
|---|---|
| SEO / public content | Server rendering (Astro, Next.js, Laravel Blade/Inertia SSR). Not a pure client-side SPA. |
| Offline-first | Local DB (SQLite / drift / expo-sqlite) + explicit sync design. Avoid backend-only data. |
| Realtime (chat, live updates) | WebSocket/SSE support: Socket.IO, Laravel Reverb, Supabase Realtime, Go websockets; at scale Centrifugo/NATS. |
| Heavy compute / high concurrency / tiny server | Go (or Rust for max performance). |
| AI / ML / data processing | Python for that part (FastAPI service or worker), even if the rest is another language. |
| Low-end devices | Tauri over Electron; Flutter/native over heavy webviews; minimal JS on web. |
| Admin-heavy CRUD / back office | Laravel + Filament, or Django admin. Huge time saver. |
| Multi-tenant SaaS | PostgreSQL with `tenant_id` everywhere (+ row-level security). Decide on day 1 (ADR). |
| Payments | Provider-hosted checkout + signed webhooks. Indonesia: Midtrans / Xendit. Global: Stripe. |
| Complex roles/permissions | Proven RBAC lib (spatie/laravel-permission, CASL, Casbin). Never ad-hoc `if role == …` everywhere. |
| File uploads / media | S3-compatible object storage (Cloudflare R2, S3, MinIO), not the app server disk. |
| Background jobs / scheduled tasks | Queue: Laravel Queues/Horizon, BullMQ (Node), Celery/RQ/arq (Python), asynq/River (Go). |

## Step 4 — Default picks by platform and tier

### Web

| Kind | S | M | L |
|---|---|---|---|
| Landing / blog / docs / content | Astro + Tailwind, static | Astro + headless CMS | Astro or Next.js + CMS + CDN |
| Web app (CRUD, dashboard, SaaS) | **PHP:** Laravel + Livewire · **TS:** Next.js + SQLite · or HTMX + small backend | **TS:** Next.js (App Router) + TypeScript + Tailwind + shadcn/ui + Drizzle + PostgreSQL + Better Auth · **PHP:** Laravel + Inertia (React/Vue) or Livewire + Filament + PostgreSQL/MySQL · **Python:** Django (admin-heavy) or FastAPI + React/Vite | Frontend: Next.js or React+Vite (TS). Backend: **Go** (chi/Echo + pgx/sqlc) for speed & low resources, or **NestJS / Hono** (TS-only team), or **Laravel + Octane** (business-heavy). PostgreSQL + Redis + queue. **Modular monolith** first. |
| API only | Hono (TS) or FastAPI | same + PostgreSQL, OpenAPI docs | Go, or NestJS; PostgreSQL, Redis, OpenAPI, rate limiting |
| E-commerce | Don't build — Shopify / WooCommerce | Medusa (TS) or Laravel-based | Custom on the L stack, only with a real reason |

### Mobile

| S | M | L |
|---|---|---|
| **Flutter** (Dart) or **React Native + Expo** (TS) — pick by language familiarity. Backend: none (local SQLite) or Supabase/Firebase. PWA if no native features are needed. | Flutter (Riverpod or Bloc, go_router, drift) **or** Expo (expo-router, TanStack Query, Zustand). Backend: own API from the Web table, or Supabase. | Flutter or RN for most products. **Native** (Kotlin + Jetpack Compose / Swift + SwiftUI) when heavy device features (BLE, AR, background processing, camera pipelines), top performance, or platform-specific UX dominate. |

Tie-breakers: web app already in TS → Expo (shared language/code). Custom, consistent UI and smooth animations on low-end Android → Flutter.

### Desktop

| S | M | L |
|---|---|---|
| **Tauri 2** (web UI + Rust core, small binaries). Internal/data tools: **Python + PySide6**. | Tauri 2 + React/Svelte/Vue + SQLite. **Electron** only when you need its ecosystem/Node APIs and size/RAM don't matter. | Tauri 2 with heavy logic in Rust, or Electron for VS Code-class apps. Windows-enterprise: **.NET** (WPF / WinUI 3; Avalonia for cross-platform). High-perf native: Qt. Flutter desktop if sharing code with a Flutter mobile app. |

### Script / CLI / automation

| Kind | Pick |
|---|---|
| One-off or small automation | **Python** run with `uv` (single file, inline deps). Windows admin tasks: **PowerShell**. Linux server tasks: **Bash**. JS libs needed: Node/Bun. |
| Repeated-use CLI (internal) | Python + Typer + Rich, or TS + commander. |
| Distributed CLI / performance | **Go** (Cobra) single binary; Rust (clap) for max performance. |
| Scraping / browser automation | Python + httpx + selectolax/BeautifulSoup; Playwright for JS-heavy sites. Respect ToS/robots. |
| Data processing / reports | Python + Polars (or pandas) + DuckDB. |
| Scheduling | cron, Windows Task Scheduler, or GitHub Actions `schedule`. |

### Other

| Kind | Pick |
|---|---|
| Chat bot | Telegram: aiogram (Py) / grammY (TS). Discord: discord.py / discord.js. WhatsApp: official WhatsApp Cloud API (unofficial libs risk bans). |
| Browser extension | WXT + TypeScript (+ React/Svelte). |
| AI / LLM app | TS: Vercel AI SDK. Python: official provider SDK + FastAPI. RAG: PostgreSQL + pgvector before a dedicated vector DB. |
| Game | Godot (2D/3D indie), Unity (commercial 3D/mobile), Phaser (2D web). |
| IoT / embedded | PlatformIO / Arduino (C++) or ESP-IDF; MicroPython for prototypes. |

## Step 5 — Supporting choices

| Concern | Default |
|---|---|
| Database | **PostgreSQL** for servers. **SQLite** for local/desktop/mobile/small single-server apps. MySQL/MariaDB if hosting requires. MongoDB only for truly document-shaped data with no relations. |
| ORM / query | Drizzle or Prisma (TS), Eloquent (Laravel), SQLAlchemy/SQLModel (Python), sqlc or pgx (Go), drift (Flutter). |
| Auth | Framework's own (Laravel Breeze/Fortify, Django auth), Better Auth (TS), Supabase Auth. Never hand-roll password hashing or crypto. |
| Cache / queue | Redis (or Valkey). |
| Email | Resend, Postmark, Amazon SES. |
| Errors / monitoring | Sentry (or self-hosted GlitchTip). |
| Hosting | Static: Cloudflare Pages / Vercel / Netlify. Apps: VPS + Docker (+ Coolify/Dokploy) = cheapest & flexible; PaaS: Railway / Render / Fly.io; Vercel for Next.js; shared hosting for small PHP. |
| Package manager | JS: pnpm (or what the project uses). Python: uv. PHP: Composer. |

## Step 6 — Sanity check before recommending

- [ ] Every Step 0 constraint satisfied.
- [ ] Each Step 3 need has an answer in the stack.
- [ ] No component is there "just in case" (no Kubernetes, microservices, GraphQL, message bus, or second database without a concrete need).
- [ ] The user can host it within budget.
- [ ] You can name the quality-gate tools for it (`quality-gates.md`).

Then present it in the format from `wf-new-project` Phase 2 and record the decision as ADR `0001-tech-stack.md`.
