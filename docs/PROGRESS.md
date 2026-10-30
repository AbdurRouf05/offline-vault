# Progress

> The "save game". Any AI must be able to continue from here with no chat history.
> Update after every completed step.

**Last updated:** 2026-10-30

## Current state
- Works:
  - Workflow Kit v0.6.0 installed.
  - Phase 1–6 (PRD, ADR, Architecture, DB, Design, Scaffold, Quality gates) selesai.
  - US-01: Setup Master PIN, hash storage aman (PBKDF2-HMAC-SHA256), buka kunci biometrik (Fingerprint/FaceID via `local_auth`), sesi runtime aman.
  - US-02: Brankas Kredensial lengkap (tambah, ubah, salin password/username ke clipboard, hapus, filter kategori, pencarian realtime) + Generator Password berentropi tinggi.
  - US-03: Catatan Offline (buat memo, sematkan/pin catatan, kategori, pencarian teks, simpan terenkripsi).
  - US-04: Migrasi Data HP Offline (.vault) — Ekspor data ke file terenkripsi AES-256-GCM dengan password mandiri + Impor file .vault untuk transfer antar-HP.
  - Verify command `flutter analyze && flutter test` lolos 100% tanpa issue.
- In progress: MVP selesai; bug ganti PIN & toggle biometrik sudah diperbaiki. Belum diuji di HP fisik (USB gagal handshake).
- Broken / known issues: None.

## Next steps
1. Uji coba langsung di emulator/perangkat fisik Android (`flutter run`).
2. Persiapan build APK release standalone (`flutter build apk --release`).
3. Penambahan fitur fase berikutnya: TOTP 2FA Authenticator & lampiran gambar terenkripsi lokal.

## Backlog
- [x] Phase 1–6: Scaffold & Quality Gates
- [x] US-01: Setup Master PIN & Buka Kunci Biometrik
- [x] Database & Repository Layer (SQLite Encrypted Storage)
- [x] US-02: Manajemen Kredensial & Generator Password
- [x] US-03: Manajemen Catatan Offline
- [x] US-04: Ekspor & Impor Cadangan Terenkripsi (.vault)

## Open questions for the user
None.

## Log (newest first)
- 2026-10-30 — refactor(backup): `.vault` encode/decode moved to pure `backup_codec.dart` (used by `BackupService`); new `tool/make_seed_vault.dart` builds an encrypted seed `.vault` from JSON on stdin (password via `SEED_VAULT_PASSWORD`, output in gitignored `build/`). Tests: `test/backup_codec_test.dart`.
- 2026-10-30 — feat(notes): `#tags` in note content become filter chips in read mode ("Semua" + `#tag (count)`); selecting one shows only tagged lines under their `## ` headings. Headings render bold, tags muted. Logic in `note_tags.dart`. Tests: `test/note_tags_test.dart`, `test/note_detail_test.dart`.
- 2026-10-30 — feat(categories): category UI — shared filter bar with "Kelola" button, Kelola Kategori screen (add/rename/delete), form dropdown with "+ Kategori baru". Wired into notes and credentials. Tests: `test/category_widgets_test.dart`.
- 2026-10-30 — feat(categories): data layer for user-editable categories (`lib/features/categories/`): list logic, persistence in `app_metadata`, rename/delete moves items. Tests: `test/category_list_test.dart`.
- 2026-10-30 — feat(notes): tapping a note opens a read-only view (`note_detail_screen.dart`) with copy and edit buttons; edits happen only via "Ubah". Tests: `test/note_detail_test.dart`.
- 2026-10-30 — fix(notes): note preview text was hardcoded black87, unreadable in dark mode — now uses colorScheme.onSurfaceVariant.
- 2026-10-30 — feat(notes): leaving the note form with unsaved changes asks Simpan / Buang / Batal (PopScope). Tests: `test/note_form_test.dart`.
- 2026-10-30 — feat(notes): content field grows with the text (minLines 12, no max) so long lists scroll with the page.
- 2026-10-30 — test: debug APK built and installed on Infinix X6853 (Android 16); app launches to the Master PIN setup screen with no errors in logcat. Manual testing by the user is next.
- 2026-10-30 — fix: biometric unlock never worked when enabled from Settings — cause: toggle only set the flag, the PIN was never cached — fix: toggle now asks for and verifies the Master PIN, then calls `enableBiometricWithPin`.
- 2026-10-30 — fix: changing Master PIN made all stored data undecryptable — cause: new PIN derived a new key but rows stayed encrypted with the old key — fix: `DatabaseService.reEncryptAll` re-encrypts in one transaction before the new PIN is persisted; tests in `test/security_test.dart`.
- 2026-10-30 — style: apply `dart format` to lib/ and test/ (code was failing the format check).
- 2026-10-30 — feat: Implement core MVP (Master PIN, Biometrics, Credential Vault, Notes, Encrypted .vault Export/Import) with 100% passing tests.
- 2026-10-30 — setup: Initial scaffold, quality gates, cipher service unit tests passing, docs completed.
