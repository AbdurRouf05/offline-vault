# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core MVP implementation:
  - Hardware-backed Master PIN setup and verification with PBKDF2-HMAC-SHA256.
  - Native biometric authentication (Fingerprint / Face Unlock) using `local_auth`.
  - Encrypted Credential Vault with search, category filtering, and clipboard integration.
  - Interactive password generator with customizable length and character sets.
  - Offline private notes with pinning, tagging, and search.
  - Encrypted `.vault` backup export and import for offline phone-to-phone migration.
  - Unit tests for cryptography primitives and backup/restore round-trip.
- Initial project scaffold with Flutter 3.38+ and Dart 3.10+.
- Architecture, PRD, DATABASE, and DESIGN system specifications.
- Strict quality gates (analyzer, linter, tests, git hooks).
