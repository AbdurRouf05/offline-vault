# Security Checklist

Apply the sections that match what the change touches. Based on OWASP Top 10 / ASVS, simplified.

## 1. Secrets & config
- [ ] No secrets (API keys, passwords, tokens, private keys) in code, tests, docs, or git history. Use env vars / secret manager.
- [ ] `.env` is in `.gitignore`; `.env.example` has placeholders only.
- [ ] Secrets never reach the client bundle (check `NEXT_PUBLIC_`, `VITE_`, Flutter/RN builds — anything shipped to devices is public).
- [ ] A secret that was ever committed or shared is **rotated**, not just deleted.
- [ ] Production has debug mode off and verbose error pages disabled.

## 2. Authentication
- [ ] Use the framework's / a proven auth library. Never hand-roll password hashing, session, or JWT crypto.
- [ ] Passwords hashed with bcrypt/argon2 (library default). Minimum length ≥ 8, check against common passwords if possible.
- [ ] Login, password reset, and OTP endpoints are rate-limited.
- [ ] Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` (or Strict). Session rotated on login.
- [ ] Tokens: short-lived access tokens; refresh tokens stored securely (mobile: Keychain/Keystore via secure storage, not plain prefs).
- [ ] Password reset tokens: random, single-use, expire quickly. Same response whether the email exists or not.
- [ ] Logout actually invalidates the session/token server-side.

## 3. Authorization (most common real-world bug)
- [ ] **Every** protected action checks permission on the server — not just hidden buttons in the UI.
- [ ] Check ownership of the **specific resource**: user A cannot read/edit `/orders/123` belonging to user B (IDOR).
- [ ] Multi-tenant: every query is scoped by tenant. No query can return another tenant's data.
- [ ] Deny by default; roles/permissions centralized (policies/guards/middleware), not scattered `if` checks.
- [ ] Admin endpoints protected and not guessable-only.

## 4. Input & injection
- [ ] All input validated on the server with a schema (type, length, format, allowed values). Client validation is UX only.
- [ ] SQL: parameterized queries / ORM only. Never build SQL with string concatenation of user input.
- [ ] No user input in shell commands. If unavoidable, use argument arrays (no shell), strict allowlists.
- [ ] Mass assignment prevented: only allowlisted fields are written (`$fillable`, DTOs, explicit picks). Users can't set `role`, `is_admin`, `price`.
- [ ] No `eval`, dynamic `require/import`, or unsafe deserialization (`pickle`, PHP `unserialize`) of untrusted data.
- [ ] Redirects only to allowlisted URLs/paths (no open redirect via `?next=`).

## 5. Output & browser
- [ ] Output escaped by the template engine; no raw HTML from users (`dangerouslySetInnerHTML`, `{!! !!}`, `v-html`) unless sanitized (DOMPurify).
- [ ] CSRF protection on cookie-based state-changing requests (framework default — don't disable it).
- [ ] Security headers: Content-Security-Policy, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, HSTS on HTTPS, frame-ancestors.
- [ ] CORS: explicit allowed origins. Never `*` together with credentials.

## 6. Files
- [ ] Uploads: validate type by content (not just extension), limit size, generate new random filenames, store outside web root or in object storage.
- [ ] Never serve user uploads as executable / HTML from your main domain.
- [ ] Paths built from user input are normalized and confined to an allowed directory (no `../` traversal).

## 7. External calls & SSRF
- [ ] If the server fetches a URL from user input: allowlist hosts, block internal/private IPs and cloud metadata (169.254.169.254).
- [ ] Webhooks (payments etc.): verify the provider's signature; process idempotently (same event twice = one effect).
- [ ] Timeouts on every outbound HTTP call.

## 8. Data protection
- [ ] Only collect personal data you need. Know where it's stored (relevant for Indonesia's UU PDP / GDPR).
- [ ] HTTPS everywhere. Sensitive data encrypted at rest when required.
- [ ] Logs and error trackers don't contain passwords, tokens, full card numbers, or ID numbers.
- [ ] API responses don't leak extra fields (password hash, internal flags, other users' emails). Use explicit response DTOs/resources.
- [ ] Backups exist and restore has been tested for anything important.

## 9. Dependencies & supply chain
- [ ] Lockfile committed. Dependency audit in CI (`pnpm audit`, `pip-audit`, `composer audit`, `govulncheck`, `cargo audit`).
- [ ] New packages: check name spelling (typosquatting), maintenance, download count. AI-suggested package names can be hallucinated — verify they exist and are the right one.

## 10. Abuse & availability
- [ ] Rate limiting on auth, expensive endpoints, and anything sending email/SMS/WA (cost abuse).
- [ ] Pagination and max limits on lists; request body size limits.
- [ ] Expensive work (exports, AI calls, image processing) goes through queues with limits.

## Platform-specific
- **Mobile:** secrets aren't safe in the app binary — keep them server-side. Use secure storage for tokens. Validate deep link params. Certificate pinning only if required.
- **Desktop (Tauri/Electron):** Tauri — minimal capabilities/permissions allowlist. Electron — `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`, validate every IPC message, never load remote content with Node access.
- **Scripts/CLI:** don't print secrets; read them from env or OS keychain; confirm before destructive operations; handle paths with spaces safely.
- **Bots:** verify the webhook secret; validate commands/user permissions; rate-limit per user.
- **AI/LLM features:** treat model output as untrusted input (escape it, never execute it directly); protect against prompt injection from user-supplied content when the model can call tools; cap tokens/cost per user.
