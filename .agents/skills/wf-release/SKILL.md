---
name: wf-release
description: Prepare and ship a release - pre-release checks, versioning, changelog, build, deploy or publish (web, mobile store, desktop installer, package, script), smoke test, and rollback plan. Use when deploying, releasing, publishing, or building for distribution.
---

# wf-release — Ship without surprises

**STOP:** every action that deploys, publishes, or touches production needs the user's explicit OK at that moment.**
Preparing and building locally is fine without asking.

## Step 1 — Pre-release checks
- [ ] Working tree clean, on the right branch, up to date.
- [ ] Verify command passes. E2E/smoke tests pass if they exist.
- [ ] `docs/PROGRESS.md` has no open item marked as release-blocking.
- [ ] Security: dependency audit + secret scan clean (or known/accepted issues documented).
- [ ] All env vars documented in `.env.example` and set in the target environment (check names, never print values).
- [ ] DB migrations reviewed: reversible? Backup taken or available? Long-running locks on big tables?
- [ ] Debug flags off in production config (debug mode, verbose errors, source maps if not intended, test keys).

## Step 2 — Version & changelog
1. Bump version using semantic versioning: MAJOR (breaking) . MINOR (new feature) . PATCH (fix).
   Update it where the stack keeps it (`package.json`, `pubspec.yaml`, `tauri.conf.json`, `pyproject.toml`, etc.).
2. Move `Unreleased` entries in `CHANGELOG.md` under the new version and date.
3. Commit `chore(release): vX.Y.Z` and tag `vX.Y.Z`.

## Step 3 — Build & ship (by target)
- **Web app / API:** build production bundle → deploy (platform CLI, Docker image, or git-push deploy) → run migrations
  (in the order the deploy needs) → check health endpoint.
- **Mobile:** set version name + build number → release build (`flutter build appbundle` / `eas build` / Gradle / Xcode)
  → signing with the user's keys (never commit keystores) → internal testing track first → store submission by the user.
- **Desktop:** release build (e.g. `pnpm tauri build`, electron-builder, PyInstaller) → code signing if available →
  installer tested on a clean machine/VM → publish (GitHub Releases or site) with checksums.
- **Library / CLI package:** build → `pnpm publish --dry-run` / `uv build` + check contents → publish.
- **Script / automation:** document usage + requirements in README; test on a clean environment; schedule (cron / Task Scheduler)
  only with user OK.

## Step 4 — After release
1. Smoke test the main flows on the released version (not local).
2. Watch logs/errors for the first minutes if there's a dashboard.
3. Write the rollback plan in the report: exact steps to go back to the previous version (and DB considerations).
4. Update `docs/PROGRESS.md` (released vX.Y.Z, date, where). Report per `AGENTS.md` §6.

## Finish
Re-read `AGENTS.md` §5 (Definition of Done) and tick every item that applies. Report per `AGENTS.md` §6.
