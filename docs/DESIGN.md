# Design System — Offline Vault

> How the product looks, feels, and talks. Every UI change follows this file.
> Anti-slop rules: `.agents/knowledge/ui-ux.md` and `.agents/knowledge/copywriting.md` always apply.

## 1. Personality
- **Three words:** Aman, Presisi, Tenang.
- **Reference products:** Bitwarden, Standard Notes, Signal Settings.
- **Not:** Menyilaukan, playful, futuristik, atau dihiasi ilustrasi 3D generic.

## 2. Color
Neutral-first. Satu warna aksen fungsional (Deep Emerald / Slate Teal).
Mendukung mode gelap (Dark) dan terang (Light) dengan kontras tinggi.

| Token | Light Theme | Dark Theme | Use |
|---|---|---|---|
| `bg` | `#F8FAFC` (Slate 50) | `#0F172A` (Slate 900) | Background layar utama |
| `surface` | `#FFFFFF` (White) | `#1E293B` (Slate 800) | Kartu kredensial, form, modal |
| `border` | `#E2E8F0` (Slate 200) | `#334155` (Slate 700) | Garis batas elemen, divider |
| `text` | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | Teks utama |
| `text-muted` | `#64748B` (Slate 500) | `#94A3B8` (Slate 400) | Keterangan sekunder, timestamp |
| `accent` | `#0D9488` (Teal 600) | `#14B8A6` (Teal 500) | Tombol utama, tab aktif |
| `accent-fg` | `#FFFFFF` | `#042F2E` | Teks di atas warna aksen |
| `danger` | `#DC2626` (Red 600) | `#EF4444` (Red 500) | Hapus kredensial, peringatan risiko |
| `success` | `#16A34A` (Green 600) | `#22C55E` (Green 500) | Berhasil salin, verifikasi valid |

## 3. Typography
- Font family: System Sans-Serif (Roboto di Android, SF Pro di iOS).
- Monospace font untuk password, PIN, dan kode kunci.
- Skala:
  - App Bar / Page Title: 20sp, Semi-bold.
  - Section Title: 16sp, Semi-bold.
  - Body: 14sp, Regular, Line-height 1.4.
  - Caption / Time: 12sp, Regular.
  - Password Monospace: 14sp, Regular (`Courier` / `monospace`).

## 4. Spacing, radius, elevation
- Skala Spacing: 4, 8, 12, 16, 20, 24, 32 (dp).
- Radius:
  - Tombol dan Input Field: 10dp.
  - Kartu & Dialog: 14dp.
- Elevasi: Flat dengan border 1dp (`surface` + `border`) untuk kesan rapi dan modern tanpa shadow berlebihan.

## 5. Layout & Navigation
- Navigasi utama menggunakan Bottom Navigation Bar dengan 3 tab:
  1. **Kredensial:** Brankas akun dan generator password.
  2. **Catatan:** Daftar catatan privat dan memo.
  3. **Pengaturan:** Master PIN, biometrik, ekspor/impor migrasi data.
- State wajib di setiap view:
  - Loading: Skeleton / spinner minimalis.
  - Empty: Penjelasan singkat dan tombol aksi langsung (misal: "Belum ada kredensial tersimpan. Tambah akun pertama Anda.").
  - Error: Pesan kesalahan jelas dalam Bahasa Indonesia dengan tombol coba lagi.

## 6. Copywriting & Voice
- Bahasa: Bahasa Indonesia lugas, profesional, tanpa emoji dekoratif berlebihan.
- Tombol aksi jelas kata kerjanya: "Simpan Kredensial", "Salin Password", "Ekspor Cadangan", "Impor Data".

