# Offline Vault

A personal, 100% offline notes app with a one-file backup to move notes to another phone (Android & iOS). No PIN, no account (ADR 0002).

## Features
- **Zero Network Permission:** 100% offline, zero cloud telemetry or internet permissions.
- **Notes:** plain text notes with editable categories, pinning, local search, and `#tag` filters inside a note (`## ` lines are headings).
- **Encrypted at rest:** note content is AES-256-GCM encrypted with a random key kept in Android Keystore / iOS Keychain. The app opens without a PIN.
- **Phone-to-phone backup (.vault):** export all notes to one plain JSON file and import it on the other phone. The file has no password.

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
