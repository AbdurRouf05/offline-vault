# ADR 0002 — Notes-only app without PIN, plain backup file

- **Date:** 2026-10-30
- **Status:** accepted (supersedes parts of the PRD v1 scope)

## Context
The app was planned as a vault: a Master PIN on first launch (the data key was derived from it), biometric unlock, a Kredensial tab for accounts and passwords, and a password-protected encrypted `.vault` backup.

The user is the only person using it, on their own phones. After testing on the phone they said: "gausah pin pin an lah ribet, bukan berankas, tapi catatan saja" (no PIN, it is a hassle; not a vault, just notes). When asked, they chose:
- remove the PIN completely (not optional);
- remove the Kredensial feature; account data is kept as normal notes;
- backup file without a password.

## Decision
- No lock screen, no PIN, no biometric. The app opens straight to Catatan.
- Notes stay encrypted at rest with a random 256-bit key created on first launch and kept in `flutter_secure_storage`. The user never sees it.
- The Kredensial tab, credential form, password generator and credential categories are removed. Tabs: Catatan, Pengaturan.
- Backup format v2: the `.vault` file is plain JSON (`{format, version: 2, exported_at, notes}`), with no password. Old v1 files are not supported.

## Consequences
- Simpler daily use and simpler migration: export, send the file, import.
- Anyone with the phone unlocked, or with the backup file, can read every note. The user accepted this.
- Existing data on the phone from the PIN-based build cannot be opened by the new build (different key); the phone needs a clean install, then the seed is re-imported.
- `local_auth` is no longer used and can be removed.
