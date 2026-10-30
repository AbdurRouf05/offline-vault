# Documents: formats, building, checking

How to produce PDF, DOCX and PPTX files that look professional and do not break, with any model.
The words themselves follow `writing.md`. The step-by-step flow is the skill `wf-docs`.

## The principle
**Write content in Markdown. Let tested templates do all the styling.** Never hand-style a document per request
(no inline fonts or colors, no raw HTML, no hand-written LaTeX or Typst for ordinary documents). The templates in
`.agents/templates/documents/` were tuned and checked visually; a model that only writes clean Markdown gets the same
neat result every time. Keep the `.md` source next to the output: to change a document, edit the source and rebuild.

## Choose the output
| The user needs | Build | Notes |
|---|---|---|
| A report, proposal or paper to read, print or submit as final | PDF (`--to pdf`) | Default. Typst engine: fast, precise, no LaTeX install |
| A file others will edit, or a campus/office that requires Word | DOCX (`--to docx`) | Styled with the kit's reference.docx, or the user's template via `--ref` |
| Both | `--to all` | PDF + DOCX from the same source |
| A presentation | PPTX (`docstyle: slides`) | `--to all` also exports a PDF of the deck via Office/LibreOffice |
| A LaTeX PDF (user asks for LaTeX, heavy math, journal class) | `--engine latex` | Needs a TeX distribution with xelatex; slower. For a journal `.cls`, write `.tex` directly |
| A spreadsheet | not this pipeline | Use a script (Python openpyxl, or CSV) |
| A change to an existing DOCX/PPTX/PDF | see "Editing existing files" | Do not regenerate it from Markdown without asking |

| Style (`docstyle`) | Looks like | Use for |
|---|---|---|
| `laporan` (default) | Cambria 11 pt, spacing 1.2, margins 2.5 cm, left-aligned headings, block paragraphs | Reports, proposals, SOPs, letters, notes |
| `akademik` | Times New Roman 12 pt, spacing 1.5, margins 4-4-3-3 cm, first-line indent, centered chapter headings | Makalah, skripsi chapters, academic papers (Indonesian campus defaults) |
| `slides` | 16:9, title at the top, calm table style | Presentations |

If the user's guideline (pedoman) differs from these defaults, override in the front matter (below), or use
`--ref their-template.docx` for Word output.

## Commands
```bash
node .agents/scripts/doc-check.mjs docs/laporan.md            # prose lint: slop, placeholders, spelling, structure
node .agents/scripts/doc-build.mjs docs/laporan.md --preview  # build PDF + PNG of every page
node .agents/scripts/doc-build.mjs docs/laporan.md --to all --preview
node .agents/scripts/doc-build.mjs docs/deck.md --to all --preview   # docstyle: slides -> PPTX + PDF
```
Options: `--to pdf|docx|pptx|all`, `--style laporan|akademik|slides`, `--engine typst|latex`, `--out <dir>`,
`--name <base>`, `--toc`, `--ref <file.docx|pptx>`, `--preview`, `--keep-typ`, `--no-check`.
Exit codes: 0 ok, 1 build failed, 2 bad usage, 3 built but doc-check found errors (fix them, do not deliver).
doc-check alone: add `--slides` for decks (automatic with `docstyle: slides`), `--strict` to fail on warnings.

Previews land in `<out>/<name>-preview/<pdf|docx|pptx>/page-NN.png`. DOCX and PPTX previews need Microsoft Office
(Windows) or LibreOffice; without them the build still works, only the preview is skipped.

## Front matter
```yaml
---
title: "Evaluasi Uji Coba Aplikasi Kasir"
subtitle: "Laporan untuk pemilik usaha"   # optional
author: "Tim Pengembang"                   # or a list: [Nama Satu, Nama Dua]
date: "25 Oktober 2026"
lang: id                                   # id (default) or en: captions "Tabel/Gambar", hyphenation, quotes
docstyle: laporan                          # laporan | akademik | slides
---
```
Optional keys: `toc: true` (or `--toc`), `numbersections: true` (numbers headings; never number them by hand),
`fontsize: 12pt`, `mainfont: "Arial"`, `linestretch: 1.5`, `papersize: letter`, `margin: {x: 2cm, y: 2.5cm}`,
`abstract: "..."`, `keywords: [a, b]`, `bibliography: ../research/refs.bib`, `csl: ieee` (see Citations). Layout keys (font, margin,
spacing) apply to the PDF; for DOCX the look comes from the reference document.

## Markdown that builds cleanly
- **Headings:** `#` is a main section (bab), then `##` and `###`. Nothing deeper. No manual numbers ("1.2 Tujuan").
- **Paragraphs:** separated by one blank line. Put a blank line before every list and table.
- **Tables:** pipe tables with a caption line after a blank line: `: Waktu layanan rata-rata (detik)`. Numbering
  ("Tabel 1.") is added automatically; refer to tables in the text as "Tabel 1", counting them yourself.
  **Keep every table row at most 72 characters.** Longer rows make Pandoc size the columns from the dash counts,
  which often squeezes one column. Too wide? Shorten headers, move units into the caption, abbreviate and explain
  under the table, transpose it, or split it into two tables.
- **Images:** `![Caption tells what to see](img/grafik.png){width=70%}`, path relative to the `.md`. Use PNG at
  150 dpi or more (SVG is fine for PDF only). Make charts with a script (for example matplotlib), save the script next
  to the image, and follow `.agents/knowledge/ui-ux.md` for colors.
- **Footnotes:** `teks.[^1]` with `[^1]: Isi catatan.` at the end of the section. Fine in documents, not in slides.
- **Math:** `$x^2$` and `$$...$$` work in PDF (Typst/LaTeX) and DOCX (native Word equations).
- **Page breaks:** avoid them; layout moves on its own. If one is truly needed, add raw blocks for each target:
  ```` ```{=typst} ```` + `#pagebreak()` and ```` ```{=openxml} ```` + `<w:p><w:r><w:br w:type="page"/></w:r></w:p>`.
- **Dashes:** `--` becomes an en dash (6--19 Oktober), `---` an em dash (use rarely).

## Citations (academic work)
Research projects get their sources from `wf-research` (search, download, read, note cards); this section is only
about printing the citations. Put the sources in a BibTeX file (`research/refs.bib`, made by `lit-fetch.mjs`) and set
`bibliography:` in the front matter, relative to the `.md` (from `docs/`: `bibliography: ../research/refs.bib`).
doc-build then runs Pandoc's citeproc for every format. In the text:

| You write | APA 7 prints |
|---|---|
| `[@sari2022]` | (Sari & Pratama, 2022) |
| `@hadi2019` | Hadi (2019); 3+ authors: Hadi dkk. (2019) with `lang: id`, Hadi et al. with `en` |
| `[@sari2022, hlm. 47]` | (Sari & Pratama, 2022, hlm. 47); write `p. 47` in English documents |
| `[@sari2022; @hadi2019]` | (Hadi, 2019; Sari & Pratama, 2022) |
| `[-@hadi2019]` | (2019), when the name is already in the sentence |

End the document with:
```markdown
# Daftar Pustaka

::: {#refs}
:::
```
**Style.** Default (no `csl:`) is **APA 7**. Still ask the user every time (campus guides differ) with the grill-me
tool; offer the bundled styles by name, no download needed: `apa` (APA 7, Recommended), `apa-6th-edition`, `ieee`
(numbered [1]), `harvard-cite-them-right`, `chicago-author-date`, `modern-language-association` (MLA),
`elsevier-vancouver` (numbered, medicine), `american-medical-association`. Set it as `csl: ieee` (bare name). A
campus or journal style not in the list: ask the user for its `.csl` file (or its name in the official CSL
repository, github.com/citation-style-language/styles), save it next to the `.md`, and set `csl: nama-file.csl`.
With `lang: id` "et al." becomes "dkk."; the page label is printed as you type it (`hlm.` or `p.`, follow the campus guide). Check the preview.

**Click behaviour (like Mendeley).** In the DOCX each citation is one Word field: one click selects the whole
citation as a grey block (so it is not edited by accident), Ctrl+click jumps to its entry in the reference list. In
the PDF a click on the citation jumps to the entry. Do not type citations or the reference list by hand; they would
lose this and drift from `refs.bib`.

**Integrity.** Every entry in `refs.bib` must be a real source that was read (note card with `status: read-full`).
Before building, run `node .agents/scripts/cite-check.mjs docs/<name>.md`: it fails on keys missing from the `.bib`,
sources without a note card, and quotes that are not in the source text. Never invent references.

## Slides
- `docstyle: slides`; one `##` heading per slide; `#` only for section divider slides.
- The slide title is the conclusion sentence; at most 6 bullets of about 12 words; or one table; or one image.
- Speaker notes: `::: notes` ... `:::` under the slide content. No footnotes (put sources in notes or a final slide).
- Tables in PPTX always take the full slide width; keep them to 3-5 columns and 6 rows.
- Long titles wrap; keep them under about 60 characters to avoid a lonely last word.
- Model: `.agents/templates/documents/contoh-slides.md`.

## Editing existing files
**If the kit built it, edit the `.md` source and rebuild.** Never patch the generated output.

For files from elsewhere (the user's Word file, a client's deck), keep their formatting:
| Task | How |
|---|---|
| Fix wording, numbers, names in a DOCX | Edit the text in place with python-docx (paragraph and run level, keeps styles), or edit `word/document.xml` inside the zip with care (one word can be split across runs). Pandoc round-trips lose comments, tracked changes, headers and custom styles |
| Rewrite a DOCX heavily | Ask first. Then `pandoc in.docx -t markdown -o draft.md --extract-media=media`, rewrite, and rebuild with `--ref in.docx` so the original styles are reused. Check the preview against the original |
| Edit a PPTX | Change text with python-pptx (keeps layouts and design). Rebuilding from Markdown replaces the design: only with the user's consent |
| Change a PDF | A PDF is an output: find its source (.md, .docx, .tex) and rebuild. No source: extract the text (`python .agents/scripts/read-doc.py in.pdf`), rebuild as a new document, and tell the user the layout will differ |
| Merge, split, rotate, fill PDF forms | Python pypdf (or qpdf). Keep the original file untouched; write a new one |
| Read or extract | To quote or cite: `python .agents/scripts/read-doc.py <file>` + `.agents/knowledge/reading.md`. Plain conversion: `pandoc in.docx -t gfm -o out.md`, `pandoc in.xlsx -t gfm` |

Installing a Python package or tool (python-docx, python-pptx, pypdf, qpdf, LibreOffice): ask the user first. Always
write to a new file (`-revisi.docx`) unless the user explicitly asks to overwrite.

## Verify before you say it is done
1. `doc-build ... --preview` exits 0 (exit 3 means doc-check errors: fix them).
2. **Look at every preview page** (open the PNGs). Check: title block; headings not left alone at the bottom of a
   page; tables complete, readable, and with numbered captions; images sharp and not cut; lists aligned; no raw
   Markdown symbols (`**`, `|`, `[@`) in the output; page numbers present; nothing overflowing the margins.
3. Read the doc-check warnings and fix the ones that are real.
4. Report the output paths, the page count, and anything you could not verify (for example "DOCX preview skipped:
   no Office installed").

## Common breakages
| Symptom | Cause and fix |
|---|---|
| A column squeezed to one word per line | Table row over 72 characters; shorten it (see Tables) |
| Big white gap before a table in the PDF | The table did not fit on the page and moved; normal. Shorten or split the table if it looks bad |
| Font looks different than expected | Font not installed; the template falls back. Check `doc-build` notes for "unknown font" |
| Citations print as `[@key]` | `bibliography:` missing in front matter, or the key is not in the `.bib` |
| Table of contents in Word shows "update field" | Normal for DOCX: right-click the TOC in Word and choose Update Field (tell the user) |
| Extra "Notes" slide at the end of a deck | A footnote in slides; move it to `::: notes` |
| `pandoc`/`typst` not found | Not installed or not on PATH; doc-build prints the install command. Ask the user before installing |

## Prerequisites
Node.js 18+, Pandoc 3.x and Typst 0.13+ (Windows: `winget install --id JohnMacFarlane.Pandoc` and
`winget install --id Typst.Typst`; macOS: `brew install pandoc typst`). Optional: Microsoft Office or LibreOffice
(DOCX/PPTX previews and slide PDFs), poppler `pdftoppm` or Python PyMuPDF (PNG previews of LaTeX PDFs), a TeX
distribution with xelatex (only for `--engine latex`).
