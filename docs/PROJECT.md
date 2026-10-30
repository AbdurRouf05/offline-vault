# Offline Vault — Technical Overview

> The technical "how": stack, architecture, commands, conventions. Keep it accurate.
> Product "what/why": `docs/PRD.md`. Look & language: `docs/DESIGN.md`.

- **Docs language:** English
- **Size tier:** S (Small)
- **Platform(s):** Mobile (Android, iOS-ready)
- **Runs on / hosting:** 100% Offline (Local on-device execution)

## Stack
| Layer | Choice | Why (short) |
|---|---|---|
| Language | Dart 3.10+ | Compiled AOT to native machine code, type-safe, null-safe |
| Framework | Flutter 3.38+ | 60/120 FPS native rendering, cross-platform Android & iOS |
| Database / Storage | SQLite + AES-256-GCM | Structured local querying with cryptographic protection |
| Key Management | Android Keystore / iOS Keychain (`flutter_secure_storage`) | Hardware-backed secure storage for Master Salt & App Keys |
| State Management | `flutter_riverpod` | Predictable, compile-time safe, decoupled dependency injection |
| Key Libraries | `local_auth`, `cryptography`, `file_picker`, `share_plus` | Native biometrics, crypto primitives, file handling |

Full reasoning: `docs/decisions/0001-tech-stack.md`.

## Architecture
**Pattern:** Feature-first modular architecture.

**Structure:**
```
lib/
├── core/
│   ├── crypto/            # AES-256-GCM, PBKDF2/Argon2 derivation, key derivation
│   ├── database/          # SQLite helper, schema, migrations
│   ├── security/          # Secure storage wrapper, auto-lock timer, clipboard cleaner
│   ├── theme/             # Design system tokens, color schemes, typography
│   └── utils/             # Formatters, validators, password generator
├── features/
│   ├── auth/              # Master PIN setup, verification, biometric prompt
│   ├── credentials/       # Vault credential list, detail, add/edit form
│   ├── notes/             # Offline notes list, markdown/text viewer, note editor
│   ├── backup/            # Export & Import encrypted .vault files
│   └── settings/          # Security settings, change PIN, biometrics toggle
└── main.dart              # App bootstrap, provider scope initialization
```

**Module rules:**
- `core/` contains no feature UI and has zero imports from `features/`.
- `features/` communicate via shared data repositories and Riverpod providers in `core/` or domain models.
- Never write plain passwords or raw credentials to unencrypted disk or app logs.

**Data model:** full schema with diagram in `docs/DATABASE.md` (mermaid + DBML, kept in sync).

**Important sequences:**
```mermaid
sequenceDiagram
  participant U as User
  participant A as AuthScreen
  participant S as SecurityService
  participant K as Android Keystore
  participant DB as EncryptedDatabase

  U->>A: Input Master PIN
  A->>S: Verify PIN against Master Hash
  S->>K: Retrieve Encrypted Storage Master Key
  K-->>S: Storage Master Key
  S->>DB: Unlock Database Session
  DB-->>A: Session Active
  A->>U: Navigate to Vault Dashboard
```

**External services:** Zero external network services. `android.permission.INTERNET` is explicitly removed.

**Security notes:**
- Master PIN is never stored directly. Stored as `PBKDF2-HMAC-SHA256` hash with unique salt.
- Export files (`.vault`) are enveloped with AES-256-GCM using a key derived from the user's chosen backup password.

## Commands
| Task | Command |
|---|---|
| Install | `flutter pub get` |
| Dev / run | `flutter run` |
| Build (Android APK) | `flutter build apk --release` |
| Test (unit/widget) | `flutter test` |
| Lint / Analysis | `flutter analyze` |
| Format check | `dart format --output=none --set-exit-if-changed .` |
| **Verify (run before every "done")** | `flutter analyze && flutter test` |

## Conventions
- Code, comments, commits: English.
- User UI & Messages: Bahasa Indonesia.
- Pure business logic and cryptographic functions must have isolated unit tests.

