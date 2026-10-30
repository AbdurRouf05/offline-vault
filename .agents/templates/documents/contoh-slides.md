---
title: "Uji Coba Aplikasi Kasir"
subtitle: "Hasil dua minggu di tiga toko"
author: "Tim Pengembang"
date: "25 Oktober 2026"
lang: id
docstyle: slides
---

<!-- CONTOH FIKTIF. Acuan gaya slide (wf-docs). Satu gagasan per slide; judul slide berupa kesimpulan, bukan topik. -->

## Kasir 35% lebih cepat di dua dari tiga toko

- Waktu layanan turun dari 94 menjadi 61 detik per pembeli
- Selisih kas hampir hilang di Sumbersari dan Candipuro
- Pasirian tertinggal karena internet sering putus

::: notes
Buka dengan hasil. Detail cara uji coba ada di laporan tertulis.
:::

## Waktu layanan per toko (detik)

| Toko       | Sebelum | Selama |
|:-----------|--------:|-------:|
| Sumbersari |      97 |     58 |
| Candipuro  |      90 |     57 |
| Pasirian   |      95 |     74 |

::: notes
Diukur dari rekaman kamera kasir, jam 16.00 sampai 19.00, 50 transaksi per toko per minggu.
:::

## Masalah utama: aplikasi butuh internet terus-menerus

- Transaksi gagal tersimpan saat koneksi putus
- Di Pasirian koneksi putus rata-rata 11 kali per hari
- Semua hari dengan selisih kas di Pasirian adalah hari gangguan jaringan

## Usulan langkah berikutnya

1. Pakai penuh di Sumbersari dan Candipuro mulai 1 November
2. Buat mode luring (sekitar dua minggu)
3. Perbaiki pencarian barang
4. Ulangi uji coba di Pasirian
