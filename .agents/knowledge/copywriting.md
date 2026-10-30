# Copywriting (UI text)

Text is part of the interface. Good UI text is **specific, short, and plain**. If it could be on any product's website, it's bad.
Follow `docs/DESIGN.md` → Voice & copy (Anda/kamu, tone, glossary).

## Banned words and patterns

**Hype / filler (English):** unlock, unleash, supercharge, revolutionize, elevate, empower, seamless(ly), effortless(ly),
cutting-edge, next-gen, game-changer, world-class, powerful, robust, leverage, harness, dive in, delve, journey,
"take X to the next level", "in today's fast-paced world", "Welcome to the future of…", "AI-powered" as a selling point.

**Hype / filler (Indonesian):** revolusioner, tingkatkan ke level berikutnya, solusi terbaik/terlengkap, tanpa batas,
canggih, maksimalkan potensi, "di era digital ini", "Selamat datang di masa depan…", "Rasakan pengalaman…".

**Patterns:** emoji in UI text; exclamation marks in normal messages; "Oops!" / "Uh-oh!" / "Yay!"; Title Case For Every Word;
rhetorical questions as headlines ("Tired of slow invoices?"); three-adjective lists ("fast, simple, and powerful");
stiff machine-translated Indonesian ("Silakan klik tombol di bawah ini untuk melanjutkan proses").

## Rules

1. **Say what it does, concretely.** "Catat penjualan dan cek stok dari satu aplikasi" — not "Solusi kasir revolusioner untuk bisnis Anda".
2. **Front-load the important word.** Users scan the first 2–3 words.
3. **Short.** Headlines ≤ 8 words. Buttons 1–3 words. Helper text one sentence.
4. **Buttons = verb + object:** "Simpan produk", "Kirim faktur", "Hapus akun". Not "Submit", "OK", "Klik di sini". The confirm
   button in a dialog repeats the action ("Hapus 3 produk"), not "Ya".
5. **Errors = what happened + what to do.** No blame, no jargon, no codes alone.
   - Bad: "Error 422: Invalid input." / "Oops! Terjadi kesalahan!"
   - Good: "Nomor HP harus 10–13 digit. Contoh: 081234567890."
   - Good: "Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi."
6. **Empty states = what will be here + first action.** "Belum ada transaksi hari ini. Transaksi yang dicatat akan muncul di sini." + [Catat transaksi]
7. **Success messages are brief and factual:** "Produk disimpan." Not "Berhasil! 🎉 Produk Anda telah berhasil disimpan!"
8. **Consistent terms.** One word per concept, from the glossary. Don't alternate "produk/barang/item".
9. **Sentence case** for titles, buttons, menu items, labels.
10. **Natural language for the audience.** Indonesian UI: everyday Indonesian, consistent "Anda" or "kamu", no needless English
    when a common Indonesian word exists (but keep familiar terms like "login", "email" if users say them that way — decide in DESIGN.md).
11. **Numbers and dates in local format.** `Rp 25.000`, `3 produk`, `11 Okt 2026`.
12. **No fake claims.** No made-up stats, testimonials, or "trusted by" logos.

## Before / after

| Before (slop) | After |
|---|---|
| "Unlock the Power of Seamless Inventory Management ✨" | "Stok selalu cocok dengan penjualan" |
| "Get Started Today!" | "Coba gratis 14 hari" (only if true) / "Buat akun" |
| "Oops! Something went wrong 😢" | "Gagal menyimpan. Coba lagi dalam beberapa detik." |
| "No data available." | "Belum ada pelanggan. Pelanggan baru muncul setelah transaksi pertama." |
| "Are you sure?" [Yes] [No] | "Hapus produk 'Kopi Susu 250ml'? Tindakan ini tidak bisa dibatalkan." [Batal] [Hapus produk] |

## Check

Read every new or changed string out loud as the target user. Ask: is it specific? is it the shortest clear version?
does it use the glossary terms? would it still make sense on a competitor's product (if yes, rewrite)?
