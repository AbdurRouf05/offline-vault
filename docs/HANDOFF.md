# Handoff

> Working memory for the next session or the next model. Read this FIRST, then `docs/PROGRESS.md`.
> Overwrite it (do not append) after every completed task and whenever the chat gets long.
> Keep it under ~150 lines: facts and pointers, not a diary. Full user messages live in `docs/CHATLOG.md`.

**Updated:** 2026-10-30 · **Model/tool:** Claude Opus 5.5 (Claude Code) · **Branch:** master · **Last commit:** f022b57 feat(backup): add pure backup codec and seed vault tool

## TL;DR
- Project: Offline Vault, a personal Flutter (Android) password and notes vault, fully offline, with encrypted `.vault` export/import to move data to another phone.
- Now: editable categories, a hashtag genre filter in note read mode, and a seed `.vault` tool are done. The anime seed vault is built in `build/anime.vault`, but it is NOT on the phone yet because adb shows the phone as "unauthorized".
- Next: the user authorizes USB debugging, then install the APK, push the vault, and the user imports it. After that comes the credentials seed (the user must paste the credentials again).
- Watch out: the credentials are real and sensitive. Never write them in code, in docs, in CHATLOG or in git.

## What the user asked for (current request)
- Seed data to try the app: (1) one anime note that keeps their original list, filterable by genre; (2) editable categories (add as many as they like, rename); (3) about 70 personal account credentials as seed data (2026-10-30).
- Anime rules: the first list is watched, in order, with ⭐ = favourite; "top 5" stays; the second list is to-watch, where empty numbers are already watched (dropped) and √/✓ = priority.

## State
- Done in this request:
  - `35db154` / `a12fca6` categories: data layer plus UI (filter bar "Kelola", Kelola Kategori screen, "+ Kategori baru" in forms), for notes and credentials.
  - `136aa7b` notes: `#tags` become filter chips in read mode, tagged lines stay under their `## ` headings (`note_tags.dart`).
  - `f022b57` backup: pure `backup_codec.dart` and `tool/make_seed_vault.dart` (JSON on stdin, password in `SEED_VAULT_PASSWORD`).
  - `build/anime.vault` (gitignored): one note "List anime", category Anime, pinned, with genre tags. Backup password: `anime123` (seed only, no secrets in it). The plaintext source is `build/anime_note.txt`; delete it after import.
  - The debug APK with all features is built at `build/app/outputs/flutter-apk/app-debug.apk` but not installed.
- Verified: `flutter analyze` -> no issues; `flutter test` -> 34 passed.
- Untagged anime (unsure of genre): rinkan biyaku, Ochi mono torare, rakasha street. "top 5" lines are left untagged on purpose.

## Next steps
1. Phone: `adb devices` must show `device`. Then `adb -s 115413743T006083 install -r build/app/outputs/flutter-apk/app-debug.apk`, `adb push build/anime.vault /sdcard/Download/`, and launch the app.
2. The user imports it via Pengaturan > Impor (password anime123). Afterwards delete the file from the phone (`adb shell rm /sdcard/Download/anime.vault`) and delete `build/anime.vault` and `build/anime_note.txt`.
3. Credentials seed: ask the user to paste them again. Parse them into JSON {title, username, password, url, category, notes} with categories Email / Game / Medsos / Keuangan / Kerja / Akun Web / Lainnya. Feed the JSON via stdin or a temp file in build/, generate the vault, push it, import it, then delete every plaintext and vault file. Recommend that the user changes important passwords (bank, Dana, Indodax, PayPal, Google), since they were pasted into a chat.
4. Later: an export/import test between two phones, then `flutter build apk --release`.

## Decisions and user preferences
- Personal single-user app. No unrequested security hardening - why: the user asked explicitly (2026-10-30).
- Known but accepted: the stored "PIN hash" equals the data key, and the biometric PIN is cached in secure storage.
- Seeding happens only through an encrypted `.vault` and the Impor feature, never through code. Credentials never go into git.
- Replies in Bahasa Indonesia, no emoji.

## Gotchas and dead ends
- The Bash tool can mangle heredocs that contain `'` or `\n` inside python strings. Use the Write tool for data files and Edit for `'\n'` in Dart.
- adb authorization keeps getting lost on this phone. The user has to tap Izinkan on the USB debugging dialog.
- gitleaks is not installed; the pre-commit secret scan is skipped.

## Read first
- `lib/features/backup/backup_codec.dart`, `tool/make_seed_vault.dart` - seed and backup format.
- `lib/features/notes/note_tags.dart`, `note_detail_screen.dart` - genre filter.
- `lib/features/categories/` - editable categories.
