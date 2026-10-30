# Handoff

> Working memory for the next session or the next model. Read this FIRST, then `docs/PROGRESS.md`.
> Overwrite it (do not append) after every completed task and whenever the chat gets long.
> Keep it under ~150 lines: facts and pointers, not a diary. Full user messages live in `docs/CHATLOG.md`.

**Updated:** 2026-10-30 · **Model/tool:** Claude Opus 5.5 (Claude Code) · **Branch:** main · **Last commit:** see `git log -1` (docs commit after a16ec6d)

- Repository: https://github.com/AbdurRouf05/offline-vault (public, main branch)
- Project: Offline Vault is now a personal notes app (Flutter, Android), fully offline, with a one-file `.vault` backup to move notes to another phone. No PIN, no Kredensial (ADR 0002).
- Now: the pivot is implemented and verified (analyze clean, 32 tests pass). The anime seed is rebuilt as v2 in `build/anime.vault`. The new debug APK is built, but NOT installed: adb showed no device.
- Next: connect the phone, install the APK, push the seed, import it on the phone, check the UI, then delete the seed files.
- Watch out: the user's credentials are real and sensitive. They are not stored anywhere. Never write them in code, docs, CHATLOG or git.

## What the user asked for (current request)
- "gausah pin pin an lah ribet, bukan berankas, tapi catatan saja" (2026-10-30). Chosen: remove the PIN completely, remove Kredensial (account data becomes normal notes), backup without a password.
- Still open from before: "mana kok gak ada datanya, coba lagi, perbaiki juga tampilannya" (the seed was not visible on the phone; fix the UI).

## State
- Done in this request:
  - `7b92e4c` docs: ADR 0002 and PRD revised.
  - `8ceff08` no PIN: `DataKeyService` creates a random 256-bit key in secure storage; `dataKeyProvider` loads it at startup; lock screen, biometric, Ganti PIN, Kunci Brankas, `reEncryptAll` and `local_auth` removed.
  - `20b1905` Kredensial removed: tabs are Catatan and Pengaturan; `CategoryScope` has only `notes`.
  - `ead56c5` backup v2: plain JSON `{format, version: 2, exported_at, notes}`; v1 rejected; Pengaturan rewritten (Ekspor goes straight to the share sheet, Impor asks one confirmation, result in a SnackBar, hint that the file is usually in Download).
  - `a16ec6d` selected filter chips readable in dark mode (theme `secondaryContainer`).
  - Docs: README, PROJECT, DATABASE, DESIGN updated for notes-only.
- Seed: `build/anime.vault` (v2, one pinned note "List anime", category Anime). Source `build/anime_note.txt`. Both gitignored; delete after import.
- APK: `build/app/outputs/flutter-apk/app-debug.apk` (built after a16ec6d).
- Not done: `CipherService.deriveKeyFromPassword` is now unused by the app (still covered by `crypto_test.dart`); left in place. App label is still "Offline Vault".

## Next steps
1. Phone: `adb devices` must list 115413743T006083 (the user may need to tap Izinkan for USB debugging). Then, from PowerShell:
   `adb install --user 0 -r build\app\outputs\flutter-apk\app-debug.apk` and `adb push build\anime.vault /sdcard/Download/anime.vault`.
   `install -r` keeps the old database. Old notes encrypted with the PIN key cannot be decrypted and are silently skipped, so the list starts empty. Ask before uninstalling or clearing app data.
2. In the app: Pengaturan > Impor catatan > Download > anime.vault > Impor. Check the anime note and the `#tag` filter chips.
3. Delete seed files: `adb shell rm /sdcard/Download/anime.vault`, `build/anime.vault`, `build/anime_note.txt`.
4. Account data as notes: the user pastes the credentials again. Make one note per group (Email, Game, Medsos, Keuangan, Kerja, Akun Web, Lainnya) via a temp seed JSON in `build/`, import, then delete every temp file on the PC and the phone. Recommend changing important passwords (bank, Dana, Indodax, PayPal, Google), since they were pasted into a chat.
5. Later: export/import test between two phones, then `flutter build apk --release`.

## Decisions and user preferences
- Notes-only app, no PIN, no backup password (ADR 0002). Do not propose locks or hardening.
- Seeding only via a `.vault` file and Impor, never through code. Credentials never go into git or CHATLOG.
- Replies in Bahasa Indonesia, no emoji.

## Gotchas and dead ends
- Run `adb push` from PowerShell; Git Bash rewrites `/sdcard/...` into a Windows path.
- The phone has a Dual Space user 999: use `--user 0` for install and `pm list packages`.
- The file picker opens on "Recent"; a pushed file only shows under Download.
- Phone screenshots may show private content (wallpaper, notifications). Take them only when needed and delete them right away.
- The Bash tool can mangle heredocs that contain `'` or `\n` inside python strings. Use the Write tool for data files.
- gitleaks is not installed; the pre-commit secret scan is skipped.

## Read first
- `docs/decisions/0002-notes-only-no-pin.md`
- `lib/core/security/data_key_service.dart`, `lib/main.dart`
- `lib/features/backup/backup_codec.dart`, `lib/features/settings/settings_screen.dart`
