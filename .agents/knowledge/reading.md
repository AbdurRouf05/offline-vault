# Reading PDF, DOCX and PPTX precisely

Use this whenever you must read a document that you will quote, cite, summarize, or take numbers from: journal papers,
theses, reports, the user's own drafts, slide decks. The goal: **nothing misread, nothing invented**. Every claim you
later write can be traced to a page and checked.

Short version (do these in order, do not skip):

1. Run `read-doc.py` on the file. Never read a PDF by guessing from its file name, the abstract online, or memory.
2. Open `report.md` first. It tells you which pages need extra care.
3. Read `text.md` a few pages at a time. Write the note card WHILE you read, not after.
4. For every flagged page (formula, table, figure, scan, garbled text), look at the PNG named in the flag, or mark the
   item "belum diverifikasi" if you cannot see images.
5. Copy quotes and numbers exactly, with the page number. `cite-check.mjs` will test them later.

## 1. Setup (once per laptop)

The reader needs Python and some libraries. Check before the first use, and never install without asking.

1. Run `node .agents/scripts/tools-check.mjs --for read` (or `--for research`). It only checks, it never installs.
2. If `docs/PROJECT.md` has a "Tools setup" section, follow what it says (the user already decided). Otherwise, if
   something is missing, ask the user ONCE with options (grill-me), for example:
   - "Install semua sekarang di latar belakang (Recommended)": precise reading of all formats, formulas as LaTeX.
     Takes a while (Docling downloads about 1-2 GB the first time), you can leave the laptop running.
   - "Install yang wajib saja": PyMuPDF, python-docx, python-pptx, Pandoc. Fast. Formulas only as images.
   - "Jangan install": the AI reads what it can and marks the rest "belum diverifikasi".
3. Write the answer in `docs/PROJECT.md` under `## Tools setup` (date, what was installed, what was refused), so the
   next model does not ask again.
4. Install in the background so the user can leave it running, and log to a file:
   - Windows PowerShell:
     `Start-Process -WindowStyle Hidden powershell -ArgumentList '-NoProfile','-Command','python -m pip install --user --upgrade pymupdf python-docx python-pptx docling *> $env:TEMP\wf-install.log'`
   - Bash (macOS/Linux/Git Bash):
     `nohup python3 -m pip install --user --upgrade pymupdf python-docx python-pptx docling > /tmp/wf-install.log 2>&1 &`
   - If your tool can run commands in the background (for example a "run in background" option), use that instead.
   - Pandoc is not a pip package: `winget install --id JohnMacFarlane.Pandoc` (Windows), `brew install pandoc` (macOS),
     or the package manager on Linux. tools-check prints the exact command.
5. When the install finishes, run tools-check again and update `## Tools setup`.

What each tool gives:

| Tool | Needed for | Without it |
|---|---|---|
| PyMuPDF (`pymupdf`) | PDF text, layout, tables, page images, formula crops | cannot read PDFs precisely: stop and ask |
| Pandoc | DOCX text with equations as LaTeX, tracked changes, comments | cannot read DOCX: stop and ask |
| python-docx | DOCX details (comments) | small loss |
| python-pptx | PPTX text, tables, chart data, speaker notes, hidden slides | cannot read PPTX: stop and ask |
| Docling (optional) | PDF formulas as LaTeX, OCR of scanned pages, a second opinion on layout | formulas only as PNG crops; scanned pages need a vision model |
| MS Office or LibreOffice | page PNGs of DOCX/PPTX (to check what the reader cannot carry) | no page images for DOCX/PPTX |

## 2. Run the reader

```
python .agents/scripts/read-doc.py research/sources/<key>.pdf --key <key>
```

- `<key>` is the BibTeX key from `research/refs.bib` (for example `vaswani2017attention`), so the output goes to
  `research/text/<key>/` and `cite-check.mjs` can find it. On macOS/Linux use `python3`.
- Long book? Read in parts: `--pages 1-30`, later `--pages 31-60` (use a different `--out` for each part, or run the
  whole file once and read text.md in chunks).
- Want every page as PNG (for a vision model): `--render all`. Default renders only flagged pages.
- Formulas present and Docling installed: Docling runs automatically, but ONLY on the pages with display formulas or
  scans, one page at a time, and writes `docling.md` with the same `<!-- page N -->` markers as text.md. It is slow on
  a normal laptop CPU: about 1 minute per display formula (measured: a 15-page paper with 7 formulas on pages 4-7 = 8 minutes), plus
  about 20 minutes and ~1 GB of downloads the very first time. Tell the user before a long run ("Docling akan membaca
  12 halaman berumus, kira-kira 30-40 menit"), and run it in the background if your tool can.
  Force it on chosen pages with `--engine docling --pages 4-5` (also for pages with only inline math); skip it with
  `--engine pymupdf`.
- `.doc` / `.ppt` (old formats): open in Word/PowerPoint or LibreOffice and save as `.docx` / `.pptx` first.

Output folder `research/text/<key>/`:

| File | What it is | When you use it |
|---|---|---|
| `report.md` | page index, counts, the list of flagged pages and why | FIRST, before text.md |
| `text.md` | the full text in reading order, `<!-- page N -->` (PDF/DOCX) or `<!-- slide N -->` (PPTX) markers | reading and quoting |
| `pages/pNNN.png` | picture of page N; `pNNN-mK.png` = close-up of formula K on page N | checking flagged items |
| `tables/` | each detected table as Markdown | numbers from tables |
| `images/` | pictures embedded in the document | figures |
| `docling.md` | Docling's version, formulas as LaTeX (only when Docling ran) | formulas, scanned pages |
| `meta.json` | title, authors, DOI candidates, counts | checking the bib entry |

## 3. Reading procedure

1. **report.md first.** Note the page count and the flagged pages. Note the DOI and check it matches the entry in
   `refs.bib` (wrong paper = stop, tell the user).
2. **Page numbers: two kinds.** `<!-- page N -->` is the PDF page (the Nth page of the file, `pdf N`). The number
   printed on the page (journal page, for example 233) is the printed page (`p. 233`). Citations use the printed page;
   cite-check uses the pdf page to find the quote. Write both: `(p. 233; pdf 4)`. If the page has no printed number
   (preprints, many reports), use the pdf number for both, `(p. 4; pdf 4)`, and write `page_numbers: pdf` in the
   note card front matter.
3. **Read in chunks** of about 3-5 pages (or one section). After each chunk, add to the note card:
   - what this part says, in your own words, with the page;
   - exact quotes you may use, copied character for character from text.md;
   - numbers (sample size, results, p-values, coefficients) with the page and the table/figure number.
   Do not read the whole paper and then write from memory: weak models mix up papers and invent numbers that way.
4. **Read the whole document** before setting `status: read-full`. If you read only some pages, set
   `status: read-partial` and list them in `pages_read:`. If you read only the abstract, `status: abstract-only`
   (such a source may not be cited for its findings).
5. **Flagged pages**: do section 4 for each flag before you use anything from that page.
6. **Teach-back** at the end (see section 7).

## 4. Hard content: what to do with each flag

### Formulas

Text extraction breaks formulas: fractions become flat lines, subscripts merge (`d_k` printed as `dk`), symbols may
vanish. Never quote a formula from text.md alone.

1. If `docling.md` exists, take the formula from it (it is LaTeX, for example `\frac{QK^T}{\sqrt{d_k}}`).
   Docling's LaTeX has two harmless quirks; clean them when you copy the formula into a note card or the draft:
   - letters of a word come out spaced, `A t t e n t i o n ( Q , K , V )`: it means `\text{Attention}(Q, K, V)`;
   - the equation number is glued on as `& & ( 1 )` at the end: drop it and write "(Eq. 1)" in the citation instead.
   Real example from a test paper: `$$A t t e n t i o n ( Q , K , V ) = \text {softmax} ( \frac { Q K ^ { T } }
   { \sqrt { d _ { k } } } ) V & & ( 1 )$$` becomes `$$\text{Attention}(Q,K,V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V$$`.
2. Check it against the crop `pages/pNNN-mK.png`, if you can see images. When docling.md and the PNG disagree, the
   PNG is right.
3. Cannot see images and no docling.md: write the formula in the note card as
   `FORMULA (p. N; pdf M): belum diverifikasi - perlu model yang bisa membaca gambar`, and tell the user in your
   report: "Rumus di halaman M perlu dicek dengan model vision (misalnya ganti model untuk langkah ini) atau dicek
   manual." Do not reconstruct the formula from memory of the "famous" version: papers change notation.
4. Keep a **symbol table** in the note card: each symbol, what it means, its unit, the page where it is defined.
   Example: `| λ | arrival rate | customers/hour | p. 5 |`. Most misunderstanding of formulas comes from not knowing
   what a symbol stands for.
5. To understand a formula, explain it in words step by step in the note card ("the numerator is..., it is divided
   by... so the result grows when..."). If you are not sure, say so; do not fake understanding.
6. In the manuscript, write formulas in LaTeX (`$...$`, `$$...$$`) and number them if the user's template does.

### Tables

1. Use the Markdown table in text.md or `tables/`, but check every number you will use against `pages/pNNN.png`.
2. "cells look MERGED" flag: the reader put several values into one cell. Rebuild the table from the PNG.
3. No vision: use only numbers from rows/columns that are clearly aligned in text.md, and mark the rest
   "belum diverifikasi".
4. Copy the table number, its title, units, and notes under the table (for example "* p < 0.05"). A number without
   its unit or note is a misreading.

### Figures and charts

1. Pictures are in `images/`; vector charts are only visible on the page PNG.
2. Describe only what you can see: axes, units, the trend, the caption. Never read exact values from a chart unless
   the text or a table states them; say "sekitar" if you estimate, and prefer the numbers the authors wrote.
3. Labels inside figures appear in text.md as `<!-- rotated text: ... -->` or scattered words: they are NOT part of
   the body text. Do not quote them as sentences.
4. No vision: use the caption and what the text says about the figure; mark the figure itself "belum dilihat".

### Code, algorithms, pseudo-code

Code is in ``` fences. Copy it verbatim; indentation matters (Python). Check it against the page PNG. Do not "fix" or
modernize code from a paper when quoting it; if you adapt it, say so.

### Scanned pages, garbled text

- "almost no text layer (scanned page?)": the page is a picture. Use `docling.md` (OCR) if it exists, or a vision
  model on the PNG. OCR makes errors with numbers and names: check them on the PNG.
- "unreadable glyph(s)": the font has no proper character map, words may come out wrong. Read the PNG for any
  sentence you will quote.
- Without both: mark the page "tidak terbaca" and tell the user.

### Two columns, footnotes, headers

The reader orders two-column pages left column then right column and joins words split by hyphens (it keeps
real hyphens such as "rata-rata"). Running headers, page numbers and footnotes may appear between paragraphs: do not
merge them into a quote. If a sentence looks cut or joined strangely, check the PNG.

## 5. DOCX (Word) specifics

- Equations from Word come out as `$LaTeX$`. Check them against the page PNG (made with Office or LibreOffice).
- **Tracked changes**: `[text]{.insertion}` is added text, `[text]{.deletion}` is removed text. The final text is
  without the deletions and with the insertions. Tell the user if a document still has unaccepted changes.
- **Comments**: `[text]{.comment-start id=... author=...}` ... `{.comment-end}`. They are reviewer notes, not the
  author's text. When revising the user's thesis from a lecturer's comments, list each comment and what you changed.
- Pictures pasted into Word (charts, screenshots) have no text: look at `images/` or the page PNG.
- Headings keep their level (`#`, `##`), so you can map the chapter structure (BAB I, II...).

## 6. PPTX (PowerPoint) specifics

- Each slide starts with `<!-- slide N -->`. Speaker notes come after the slide text as a line
  `> Catatan pembicara (speaker notes): ...`; they often hold the real explanation.
- **Hidden slides** are marked `<!-- slide N (HIDDEN in the show) -->` and flagged: they are not shown in the
  presentation. Mention it if you use them. `pages/pNNN.png` is always slide NNN; hidden slides have no PNG.
- **Charts**: the numbers come from the chart's own data, which may include series not visible on the slide. Check
  the rendered slide for what the audience actually sees.
- **SmartArt and embedded objects**: their text may be missing. Read the rendered slide PNG.
- Text inside pictures is not in text.md.

## 7. Teach-back (end of each source)

At the end of the note card, write in 5-8 lines, without looking back at the text:

1. The research question and why it matters.
2. Method: design, data, sample, analysis.
3. The main findings with their numbers and pages.
4. Limitations the authors state.
5. How it relates to the user's research question (supports, contradicts, method to borrow).

Then check each line against the text. Anything you cannot find on a page is a memory error: delete or fix it. This
step catches the most common failure of weaker models: mixing two papers or "remembering" findings the paper does not
contain.

## 8. What a cheap model can and cannot do here

| Task | Text-only model (cheap) | Vision model | With Docling |
|---|---|---|---|
| Body text, quotes, page numbers | yes (from text.md) | yes | yes |
| Tables with clean alignment | yes, check flags | yes, check the PNG | yes |
| Merged or complex tables | no: "belum diverifikasi" | yes, from the PNG | often |
| Formulas | no: "belum diverifikasi" | yes, from the crops | yes (LaTeX) |
| Figures / charts | caption and text only | yes | captions only |
| Scanned pages | no | yes | yes (OCR) |
| Understanding a hard formula or method | partly: explain step by step, say when unsure | same | same |

When a step needs more than the current model can do, say it plainly to the user in Bahasa Indonesia, name the pages,
and offer the options: switch to a vision-capable model for that step, install Docling (section 1), or the user
checks it manually. Never fill the gap by guessing.

## 9. Note card checklist

The note card template is `.agents/templates/research/NOTE.md` (saved as `research/notes/<key>.md`). Before you
mark it done:

- [ ] front matter `status:` is honest (read-full / read-partial / abstract-only) and `pages_read:` is filled
- [ ] every quote is a line `> "exact text" (p. N; pdf M)` copied from text.md
- [ ] every number has a page and table/figure number
- [ ] every flagged page was handled (verified on the PNG, from docling.md, or marked "belum diverifikasi")
- [ ] symbol table for formulas, if any
- [ ] teach-back written and checked
- [ ] `journal_check:` filled (see research-sources.md section 4)

Then run `node .agents/scripts/cite-check.mjs <manuscript.md>` whenever you have cited the source; it checks the quotes
against text.md.
