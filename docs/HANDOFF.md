# Handoff

> Working memory for the next session or the next model. Read this FIRST, then `docs/PROGRESS.md`.
> Overwrite it (do not append) after every completed task and whenever the chat gets long.
> Keep it under ~150 lines: facts and pointers, not a diary. Full user messages live in `docs/CHATLOG.md`.

**Updated:** 2026-10-30 · **Model/tool:** Claude Opus 5.5 (Claude Code) · **Branch:** master · **Last commit:** f885926 fix(settings): cache PIN when enabling biometric from settings

## TL;DR
- Project: Offline Vault, a personal Flutter (Android) password and notes vault, fully offline, with encrypted `.vault` export/import to move data to another phone.
- Now: MVP done, two user-facing bugs fixed. Not yet run on a real phone.
- Next: get the phone connected (USB or wireless debugging), `flutter run`, then test export on phone A and import on phone B.
- Watch out: the user does NOT want stricter PIN/crypto hardening. Only fix things that break data or the backup/migration flow.

## What the user asked for (current request)
- "jangan terlalu ketat soal sandi atau pin, ini saya pakai sendiri" / "saya hanya ingin aplikasi pindah di hp saya yang lain ... backup data" (2026-10-30)
- "perbaiki yang perlu diperbaiki" (2026-10-30)
- Interpreted as: fix bugs that cause data loss or broken features, skip security hardening.

## State
- Done in this request:
  - `2a3a166` style: dart format for the whole codebase (it was failing the format check).
  - `462935d` fix: changing the Master PIN made all data unreadable. Now `DatabaseService.reEncryptAll` re-encrypts in one transaction before the new PIN is saved. Tests: `test/security_test.dart`.
  - `f885926` fix: the biometric toggle in Settings never cached the PIN, so fingerprint unlock always failed. It now asks for and verifies the PIN.
- In flight: nothing.
- Verified: `flutter analyze` -> no issues; `flutter test` -> 8 passed; `dart format --set-exit-if-changed` -> 0 changed.
- Not verified: anything on a real device (no device connected). The biometric fix has no automated test (UI + local_auth platform channel).

## Next steps
1. Connect the phone. Windows showed "Unknown USB Device (Device Descriptor Request Failed)", VID_0000: a USB handshake failure, not a driver problem. Suggested: full shutdown of the laptop, restart the phone, clean the port, try another port/cable, or use Wireless debugging (`adb pair` / `adb connect`).
2. `flutter run` on the phone. Smoke test: setup PIN, add a credential and a note, change the PIN, and confirm the data is still readable.
3. Test migration: export `.vault` on phone A, import on phone B, check the counts and contents.
4. Then: `flutter build apk --release`.

## Decisions and user preferences
- Personal single-user app. No unrequested security hardening (key wrapping, lockout, FLAG_SECURE) - why: the user asked explicitly (2026-10-30).
- Known but accepted: the stored "PIN hash" equals the data key, and the biometric PIN is cached in secure storage. Do not raise these again unless asked.
- Replies in Bahasa Indonesia, no emoji.

## Gotchas and dead ends
- `dart format lib test` reformats every file. Run it on its own before feature work so feature diffs stay clean (now done once).
- No `sqflite_common_ffi` dev dependency, so DB code is not unit-tested. Key rotation is tested through the `reEncrypt` callback of `SecurityService.changeMasterPin`.
- gitleaks is not installed; the pre-commit secret scan is skipped.

## Open questions
- None.

## Read first
- `lib/core/security/security_service.dart` - PIN, key derivation, biometric.
- `lib/features/backup/backup_service.dart` - `.vault` export/import (the user's main goal).
- `lib/features/settings/settings_screen.dart` - UI for change PIN, biometric, export/import.
