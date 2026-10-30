---
name: wf-security-audit
description: Run a security audit of the project - automated scans (dependencies, secrets, static analysis) plus a manual checklist review by area - and produce a severity-ranked report with fixes. Use for security checks, before launch, or when handling sensitive data.
---

# wf-security-audit — Defensive review of your own project

Scope: the user's own code and configuration. Never attack or probe systems the user doesn't own.
Never run exploits against production. Never print real secrets in output — show only location and type.

## Step 1 — Map the attack surface
From `docs/PROJECT.md` and the code, list:
- Entry points: routes/endpoints, forms, file uploads, webhooks, CLI args, deep links, IPC (desktop), message handlers (bots).
- Auth: how users log in, how sessions/tokens work, roles and what each can do.
- Sensitive data: passwords, tokens, personal data, payment data — where it is stored, logged, and sent.
- External calls: third-party APIs, URLs fetched based on user input, shell commands executed.

## Step 2 — Automated scans
Run what fits the stack (install as dev tools if missing; ask first if the user prefers not to):

| Check | Tools |
|---|---|
| Vulnerable dependencies | `npm audit` / `pnpm audit`, `pip-audit`, `composer audit`, `govulncheck ./...`, `cargo audit`, `dotnet list package --vulnerable`, `flutter pub outdated` |
| Secrets in code & git history | `gitleaks detect` (or `trufflehog git file://.`) |
| Static analysis | `semgrep --config auto` (multi-language), `bandit -r .` (Python), Larastan (PHP), ESLint security plugins (JS) |

Record raw results, then triage: real issue vs false positive (explain why for each false positive).

## Step 3 — Manual review
Go through `.agents/knowledge/security.md` section by section, only for areas that exist in this project.
For each item: [OK] ok (with file evidence) / [ISSUE] issue / [N/A] not applicable.
Focus hardest on: **authorization on every protected action** (most common real-world bug), input validation,
secrets handling, and file uploads.

## Step 4 — Report
Save to `docs/security/audit-YYYY-MM-DD.md`:
```
# Security audit — YYYY-MM-DD
Scope: …   Tools run: …   Not covered: …

## Findings
### [CRITICAL|HIGH|MEDIUM|LOW] <title>
- Location: file:line
- Risk: <what an attacker could do, concretely>
- Fix: <specific change>
- Status: open
```
Severity guide — CRITICAL: remote takeover, auth bypass, leaked live secrets, mass data exposure.
HIGH: access to other users' data, injection, stored XSS. MEDIUM: limited-impact issues, missing hardening on sensitive paths.
LOW: best-practice gaps.

## Step 5 — Fix
CHECKPOINT: show the summary to the user and ask which findings to fix. Fix each with `wf-bugfix` discipline (test proving the hole
is closed where possible). Leaked secrets: tell the user to **rotate** them — removing from code is not enough.
Update the report's Status column and `docs/PROGRESS.md`.

## Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item that applies. Report per `AGENTS.md` §6.
