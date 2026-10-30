# ADR 0001 — Tech Stack Selection for Offline Vault

- **Date:** 2026-10-30
- **Status:** accepted

## Context
Aplikasi adalah brankas offline personal untuk menyimpan kredensial dan catatan sensitif pada perangkat mobile, dengan kebutuhan migrasi data antar-ponsel (Android dan potensi ekspansi ke iOS). Diperlukan teknologi yang ringan, cepat, aman untuk kriptografi lokal, dan mudah dipelihara.

Evaluasi terhadap opsi Rust:
- Rust sangat cepat untuk komputasi murni/CLI, namun ekosistem UI mobile cross-platform (Tauri Mobile) mengandalkan WebView yang justru meningkatkan konsumsi RAM dan latensi render.
- Framework Rust native (Slint/Iced) masih eksperimental dalam menangani integrasi spesifik OS mobile (Android Keystore, iOS Keychain, Biometrics, sandboxed file picking).
- Toolchain Rust (`cargo`) belum terpasang di sistem pengguna.

## Decision
Memilih **Flutter (Dart AOT)** sebagai tech stack utama dengan spesifikasi:
- **Framework & Runtime:** Flutter 3.38+ (Dart 3.10+) yang dikompilasi langsung ke binary ARM64 native.
- **State Management:** Riverpod (`flutter_riverpod`) untuk reaktivitas bersih, testable, dan tanpa boilerplate.
- **Penyimpanan Lokal:** `sqflite` / `sqflite_common_ffi` dengan enkripsi payload AES-256-GCM (`cryptography`) dan `flutter_secure_storage` untuk kunci enkripsi di Android Keystore / iOS Keychain.
- **Autentikasi Biometrik:** `local_auth` untuk integrasi native BiometricPrompt & Face Unlock.
- **Penanganan File:** `file_picker` dan `share_plus` untuk ekspor/impor file `.vault`.

## Consequences
- Keuntungan:
  - APK ringan (~15–20 MB) dan startup instan tanpa overhead runtime JavaScript / WebKit.
  - Kompatibel 100% untuk Android dan iOS di masa depan dengan basis kode tunggal.
  - Izin jaringan dapat ditiadakan secara total dari manifes Android (`android.permission.INTERNET` di-remove).
- Trade-off:
  - Sedikit lebih besar beberapa MB dibanding murni Native Kotlin (~10 MB), namun memberikan jaminan portabilitas multiplatform (Android + iOS) tanpa perlu menulis ulang UI di Swift.

