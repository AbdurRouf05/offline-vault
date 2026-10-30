# Writing documents people read

How to write reports, proposals, papers, articles, letters, SOPs and slides that read like a careful human wrote
them. This file covers the words; `documents.md` covers formats, building and checking the output.
Style references: `.agents/templates/documents/contoh.md` (report) and `contoh-slides.md` (slides).

## 1. Paragraphs carry the explanation
The most common sign of AI writing is an explanation chopped into bullets with bold labels. Readers of reports and
papers expect connected reasoning, and reasoning lives in paragraphs.

- **One paragraph, one move.** Open with a topic sentence that states the point. Follow with 2-5 sentences that
  support it: a number, an example, a cause, a comparison, or a source. End, if useful, with a sentence that leads
  into the next paragraph.
- **Length.** Usually 60-150 words (3-6 sentences). Two very short paragraphs in a row mean the thought was cut in
  pieces; join them. Over ~200 words means two moves; split them.
- **Read the topic sentences only.** If they tell the whole story of the section in order, the structure is right.

### When a list is right, and when it is not
| Use a list (or table) | Use paragraphs |
|---|---|
| Steps the reader will carry out in order (numbered) | Why something happened, what it means |
| Parallel items the reader scans or ticks off: requirements, tools, rumusan masalah, tujuan penelitian, checklist | Comparing options and weighing trade-offs |
| Items with the same shape and no logical link between them | Items connected by because, therefore, but, although |
| Reference lists, appendices, short recommendation lists | Background, analysis, discussion, conclusion, summary |

Rules for lists that stay: introduce them with a full sentence ending in a colon; 3-7 items; the same grammatical form
for every item; no bold label on every item; at most two levels; and a paragraph after the list that says what the
items mean together.

Tables are for data with two dimensions (items by attributes) or numbers the reader will compare. Mention every table
and figure in the text before it ("Tabel 1 menunjukkan ..."), then interpret it: tell the reader what to notice. Do not
repeat every cell in prose.

## 2. Sentences
- One main idea per sentence, 15-25 words on average, with some shorter and some longer for rhythm.
- **Concrete beats abstract.** Numbers, names, places, dates. "Waktu layanan turun dari 94 menjadi 61 detik", not
  "efisiensi meningkat secara signifikan".
- **Every claim has support:** data, a source, or reasoning shown in the text. Never invent numbers, quotations,
  studies or references. If support is missing, ask the user or leave the marker `[perlu sumber]` / `[perlu data]`;
  `doc-check` treats markers as errors, so they cannot slip into a final file.
- **Start with the point.** Cut warm-up sentences that only announce what comes next.
- **Show the logic between sentences** with real connectors: namun, sebaliknya, akibatnya, oleh karena itu, dengan
  demikian, meskipun. Do not start three paragraphs in a row with the same words.
- **One term, one meaning.** Define a term at first use, then keep using exactly that term. Synonyms for variety
  confuse readers of technical text.
- **Hedge as much as the evidence allows.** "menunjukkan", "mengindikasikan", "kemungkinan besar" for a small sample;
  "membuktikan" only when it really proves.
- Active voice when the actor matters. The Indonesian passive (di-) is normal in methods sections.

## 3. What makes text read like AI (avoid)
| Pattern | Instead |
|---|---|
| Grand openers: "Di era digital saat ini", "Dalam dunia yang terus berkembang", "Tidak dapat dipungkiri" | Start with the specific fact or problem |
| Stock phrases: "memainkan peran penting", "menjadi kunci", "solusi inovatif", "langkah strategis" | Say what it does, with a number if possible |
| Buzzwords: holistik, sinergi, lanskap, ekosistem, menavigasi, revolusioner, transformatif | Plain words, or remove |
| "Berikut adalah ..." before every list, "Kesimpulannya, ..." after every section | Let the content flow; conclude once, at the end |
| `**Label:** text` bullets for an explanation | A paragraph |
| Headings every two sentences, headings as questions ("Mengapa Ini Penting?") | Fewer, descriptive headings (max 3 levels) |
| "tidak hanya ... tetapi juga" and triplets of adjectives in every paragraph | Once per document at most |
| Intensifiers without evidence: sangat, signifikan, luar biasa | The number that shows it |
| Bold scattered through paragraphs, em dashes everywhere, emoji | Bold only for a term being defined; commas or parentheses |
| English: delve, tapestry, crucial, seamless, leverage, robust, "in today's fast-paced world", "it's important to note" | Plain verbs, direct statements |

`node .agents/scripts/doc-check.mjs <file.md>` flags most of these mechanically. It cannot judge content: also read
the text once from the reader's side.

## 4. Indonesian (EYD V / PUEBI)
- **Standard spelling:** analisis, risiko, silakan, mengubah, praktik, kualitas, aktivitas, efektif, objek, metode,
  persentase, jadwal, izin, hakikat, sistem. doc-check knows the common mistakes.
- **di- as prefix vs preposition:** "ditulis", "dikirim" (joined); "di rumah", "di dalam" (separate). Same for ke-.
- **Numbers:** spell out numbers that fit in one or two words in running text (dua, lima belas, seratus); use digits
  for data, measurements and series (25 kg, 4.812 transaksi, 3 dari 14 hari). Thousands with a dot, decimals with a
  comma: 1.250,5. Percent without a space: 35%. Money: Rp15.000. Never start a sentence with digits.
- **Dates and times:** 25 Oktober 2026; ranges with an en dash, written `6--19 Oktober` in Markdown; pukul 16.00.
- **Capitals in titles and headings:** capitalize every word except conjunctions, prepositions and particles (dan,
  di, ke, dari, yang, untuk, pada) unless first. Pick one heading style and keep it throughout.
- **Foreign terms** not yet absorbed are italic at first use: *dashboard*, *machine learning*.
- **Abbreviations:** write them out at first use, then use the short form: usaha mikro, kecil, dan menengah (UMKM).
- **Avoid:** "di mana" as a connector (use yang, tempat, dengan), "merubah", "sangat ... sekali", "daripada" meaning
  "dari", "kita" in formal reports (use "kami" for the writing team, or an impersonal sentence).

## 5. Structure by document type
**Laporan** (report to someone who decides). Ringkasan first: the main finding and the recommendation in one
paragraph, so a busy reader can stop there. Then Latar Belakang, Cara/Metode, Hasil (tables and figures, each
interpreted), Kendala or Pembahasan, Rekomendasi (a short list is fine), Lampiran. Model: `contoh.md`.

**Proposal** (asking for approval or money). Latar Belakang with evidence of the problem, Tujuan, Ruang Lingkup,
Metode or Rencana Kerja, Jadwal (table), Anggaran (table), Indikator Keberhasilan, Penutup. The reader must see what
they get, when, and for how much.

**Makalah, artikel ilmiah, skripsi** (style `akademik`). The Pendahuluan is built from moves, one or more paragraphs
each: (1) the broad context, with data and citations; (2) the specific problem and the gap, meaning what earlier work
found and what is still missing; (3) the aim and contribution of this work. Rumusan masalah and tujuan are numbered
lists, which is expected there. The Tinjauan Pustaka is organized by theme, not one paragraph per paper: synthesize
("Beberapa penelitian menemukan X [@sari2022; @hadi2019], tetapi belum ada yang ...") instead of listing "Sari (2022)
meneliti ... Hadi (2019) meneliti ...". Metode is in past tense with enough detail to repeat the study. Hasil and
Pembahasan go result, then comparison with earlier studies, then explanation, then implication. Kesimpulan answers
each rumusan in the same order and adds no new data; Saran is concrete. Cite only real sources that the user gave or
that you verified; follow the campus guideline (pedoman) when the user has one.

**Artikel opini or esai.** Open with a concrete fact or scene, not a grand opener. State the thesis in the first or
second paragraph. Each body paragraph carries one argument with evidence; one paragraph answers the strongest
counterargument. Close with a consequence or a call to action, not a recap. Few headings, no bullets.

**Surat resmi.** Kop, nomor, lampiran, perihal, tempat and date, addressee, "Dengan hormat,". An opening paragraph
states the purpose; one or two paragraphs give details; a closing paragraph ("Atas perhatian Bapak/Ibu, kami ucapkan
terima kasih."). "Hormat kami,", name and position. One page. Build with style `laporan` and leave `title` out of the
front matter.

**SOP or panduan.** Tujuan, Ruang Lingkup, Definisi, Penanggung Jawab, Prosedur, Catatan/Peringatan, Riwayat Revisi.
The procedure is a numbered list: one action per step, imperative verb first, the expected result where it helps.
Lists are correct here.

**Notulen rapat.** A small table (date, place, attendees), then decisions as short paragraphs, then an action table
(what, who, deadline).

**Slides.** One message per slide. The title is the conclusion as a sentence ("Waktu layanan turun 35% di dua toko",
not "Hasil"). At most 6 bullets of about 12 words, or one table, or one figure. Explanations go in speaker notes
(`::: notes`). Model: `contoh-slides.md`.

## 6. Process
1. **Brief.** Purpose, reader, the decision or action the reader should take, length, format, deadline, required
   template or pedoman, and the sources or data provided. Missing and important → ask with the grill-me tool.
2. **Outline.** Headings plus one sentence per section that states its point. For long documents, show it first.
3. **Draft** section by section, topic sentences first.
4. **Revise.** Read the topic sentences only; cut repetition; replace vague words with specifics; check that terms
   and numbers are consistent across sections (the same figure must not appear as 61 in one place and 62 in another).
5. **Check and build:** doc-check, fix errors and most warnings, build with preview and look at every page
   (`documents.md`).

## 7. Example
Fictional content, written for this guide.

Weak (reads like AI):

```markdown
## Manfaat Aplikasi Antrean

Di era digital saat ini, aplikasi antrean memainkan peran penting dalam pelayanan kesehatan. Berikut manfaatnya:

- **Efisiensi:** Pasien tidak perlu menunggu lama.
- **Transparansi:** Pasien dapat melihat nomor antrean secara real-time.
- **Kenyamanan:** Ruang tunggu menjadi lebih lega.
- **Inovasi:** Puskesmas menjadi lebih modern.

Kesimpulannya, aplikasi antrean merupakan solusi inovatif yang sangat bermanfaat.
```

Better:

```markdown
## Dampak Aplikasi Antrean

Sejak aplikasi antrean dipakai pada Maret 2026, pasien Puskesmas Tempeh rata-rata menunggu 38 menit sebelum
diperiksa, turun dari 85 menit pada bulan sebelumnya. Penurunan terbesar terjadi pada pagi hari. Sebelumnya banyak
pasien datang sejak pukul 06.00 hanya untuk mengambil nomor, sedangkan kini nomor dapat diambil dari rumah sehingga
pasien baru datang sekitar 20 menit sebelum gilirannya.

Ruang tunggu juga tidak lagi penuh. Pada pukul 09.00, petugas mencatat rata-rata 25 orang di ruang tunggu, padahal
sebelumnya sekitar 60 orang. Namun, pasien lanjut usia yang tidak memiliki ponsel pintar belum merasakan manfaat
ini. Mereka masih mengambil nomor di loket dan menunggu lebih lama karena nomor dari aplikasi dipanggil lebih dulu.
Urutan panggilan ini perlu diatur ulang sebelum aplikasi dipakai di puskesmas lain.
```

The second version gives numbers instead of labels, explains cause and effect, names a limitation, and ends with a
consequence the reader can act on.
