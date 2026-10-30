---
title: "Evaluasi Uji Coba Aplikasi Kasir di Tiga Toko"
subtitle: "Laporan singkat untuk pemilik usaha"
author: "Tim Pengembang"
date: "25 Oktober 2026"
lang: id
docstyle: laporan
---

<!-- CONTOH FIKTIF. Dipakai sebagai acuan gaya penulisan dan format (wf-docs). Angka di sini bukan data nyata. -->

# Ringkasan

Selama dua minggu uji coba, aplikasi kasir dipakai untuk 4.812 transaksi di tiga toko. Waktu rata-rata melayani satu pembeli turun dari 94 detik menjadi 61 detik, dan selisih kas harian hampir hilang di dua toko. Toko ketiga belum merasakan manfaat yang sama karena jaringan internetnya sering putus. Kami menyarankan aplikasi dipakai penuh di Toko Sumbersari dan Toko Candipuro mulai November, sedangkan Toko Pasirian menunggu mode luring selesai dibuat.

# Latar Belakang

Sebelum uji coba, ketiga toko mencatat penjualan di buku tulis lalu menyalinnya ke Excel setiap malam. Cara ini lambat pada jam ramai dan membuat kesalahan sulit dilacak. Pemilik toko baru tahu ada selisih kas keesokan harinya, ketika catatan sudah sulit dicocokkan dengan uang di laci. Aplikasi kasir dibuat untuk memindahkan pencatatan ke saat transaksi terjadi, sehingga laporan harian tersedia begitu toko tutup.

# Cara Uji Coba

Uji coba berlangsung pada 6--19 Oktober 2026 dengan perangkat yang sudah dimiliki toko, yaitu satu ponsel Android dan satu printer struk Bluetooth. Kasir dilatih selama satu jam sebelum toko buka pada hari pertama. Setiap toko menjalankan langkah yang sama:

1. Memasukkan daftar barang dan harga dari Excel lama.
2. Mencatat semua transaksi di aplikasi, sementara buku tulis tetap diisi sebagai cadangan.
3. Mencocokkan laporan aplikasi dengan uang di laci setiap malam.

Waktu layanan diukur dari rekaman kamera kasir pada jam ramai, yaitu pukul 16.00--19.00, sebanyak 50 transaksi per toko per minggu.

# Hasil

Tabel 1 merangkum perbandingan sebelum dan selama uji coba.

| Toko       | Transaksi | Sebelum | Selama | Hari selisih kas |
|:-----------|----------:|--------:|-------:|-----------------:|
| Sumbersari |     2.104 |      97 |     58 |        1 dari 14 |
| Candipuro  |     1.689 |      90 |     57 |        0 dari 14 |
| Pasirian   |     1.019 |      95 |     74 |        5 dari 14 |

: Waktu layanan rata-rata (detik) sebelum dan selama uji coba, serta jumlah hari dengan selisih kas

Penurunan waktu layanan terbesar terjadi di Sumbersari dan Candipuro. Di dua toko ini kasir tidak lagi menghitung kembalian di kertas, dan pembeli yang membeli barang yang sama tidak perlu menunggu harga dicari. Selisih kas juga hampir hilang karena setiap transaksi tercatat dengan jam dan nama kasir.

Pasirian tertinggal karena sinyal internet di lokasi itu lemah. Saat koneksi putus, transaksi gagal tersimpan dan kasir kembali ke buku tulis, sehingga data hari itu tidak lengkap.^[Rata-rata koneksi putus 11 kali per hari di Pasirian, dibandingkan kurang dari dua kali di toko lain.] Lima hari dengan selisih kas di toko ini seluruhnya terjadi pada hari dengan gangguan jaringan.

# Masalah yang Ditemukan

Masalah utama adalah ketergantungan pada internet. Aplikasi saat ini mengirim setiap transaksi langsung ke server, sehingga transaksi tidak bisa dicatat ketika koneksi hilang. Untuk toko di daerah dengan sinyal tidak stabil, kondisi ini membuat aplikasi justru menambah pekerjaan.

Masalah kedua lebih kecil tetapi sering dikeluhkan kasir. Pencarian barang hanya mencocokkan awal nama, sehingga "gula" tidak menemukan "Gulaku 1 kg". Kasir akhirnya menggulir daftar secara manual pada jam ramai.

# Rekomendasi

1. Pakai aplikasi penuh di Sumbersari dan Candipuro mulai 1 November 2026, tanpa buku tulis cadangan.
2. Buat mode luring: transaksi disimpan di ponsel lalu dikirim saat koneksi kembali. Perkiraan pengerjaan dua minggu.
3. Perbaiki pencarian agar mencocokkan kata di bagian mana pun dalam nama barang.
4. Ulangi uji coba di Pasirian setelah mode luring selesai.
