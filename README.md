# Offline Vault

A secure, 100% offline personal vault for credentials and private notes, with encrypted backup and migration support across mobile devices (Android & iOS).

## Features
- **Zero Network Permission:** 100% offline, zero cloud telemetry or internet permissions.
- **Hardware-Backed Master Auth:** Master PIN with PBKDF2 key derivation and native BiometricPrompt/FaceID unlocking.
- **Credential Vault:** Store accounts, passwords, URLs, and secrets with AES-256-GCM encryption.
- **Secure Password Generator:** Configurable entropy generator (length, uppercase, lowercase, numbers, symbols).
- **Private Notes:** Plaintext/Markdown notes with categorization, pinning, and instant local search.
- **Encrypted Migration (.vault):** One-click portable encrypted backup file for seamless phone-to-phone migration.

## Requirements
- Flutter SDK 3.38+ (Dart 3.10+)
- Android SDK 24+ (Android 7.0+) or iOS 14+

## Setup
```bash
flutter pub get
```

## Run
```bash
flutter run
```

## Test & Verify
```bash
flutter analyze && flutter test
```

## Project Docs
- `docs/PRD.md` — Product requirements, user stories, and acceptance criteria
- `docs/PROJECT.md` — Technical architecture, module boundaries, and conventions
- `docs/DATABASE.md` — SQLite schema and ER diagram
- `docs/DESIGN.md` — Design system, color tokens, and copywriting rules
- `docs/PROGRESS.md` — Task progress and backlog state
- `docs/decisions/` — Architecture decision records
