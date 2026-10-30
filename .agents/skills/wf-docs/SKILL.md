---
name: wf-docs
description: Write, build, edit, convert or review documents for people - reports, proposals, makalah/skripsi chapters, articles, letters, SOPs, meeting notes and slide decks - as PDF, DOCX or PPTX that look neat, do not break, and read well (paragraph-first, no AI slop). Markdown source plus tested templates, a prose lint, and a visual check of every page. Use when the user asks for a document, laporan, proposal, makalah, surat, presentasi/slide, or to edit/convert/fix a .docx, .pptx or .pdf.
---

# wf-docs — Documents that read well and look right

The quality comes from three things a weak model can follow: **fixed templates** (styling is never improvised),
**explicit writing rules** (`.agents/knowledge/writing.md`), and **checks** (`doc-check` lint plus looking at every
rendered page). Formats and commands: `.agents/knowledge/documents.md`.

## Ground rules
- **Paragraph-first.** Explanations, reasons, analysis and conclusions are paragraphs. Lists only for steps, parallel
  items to scan, rumusan/tujuan, checklists and references (`writing.md` §1).
- **Markdown source + templates.** Write `docs/<name>.md` (or where the user wants it) and build with
  `node .agents/scripts/doc-build.mjs`. No hand styling, no raw HTML/LaTeX/Typst in ordinary documents.
- **Never invent facts, numbers, quotes or references.** Missing → ask, or leave `[perlu data]` / `[perlu sumber]`
  (doc-check blocks delivery until they are resolved).
- **Look before you deliver.** Build with `--preview` and open every page image. A document is not done until you
  have seen it.
- **Keep the source.** The `.md` (and `.bib`, images, chart scripts) stays next to the output so anyone can rebuild.
- **Ask before installing** tools or packages, and before overwriting a user's file (write `-revisi` copies).
- Language of the document: what the user asks for (default Indonesian, `lang: id`). Replies to the user: Indonesian.

## Pick the mode
| The user wants | Mode |
|---|---|
| A new document or deck | A. Create |
| Changes to an existing .docx/.pptx/.pdf | B. Edit |
| A file turned into another format, or text pulled out of it | C. Convert / extract |
| Feedback on, or a rewrite of, a text | D. Review / rewrite |

## A. Create
1. **Brief.** Collect: purpose, reader, what the reader should decide or do, document type, length, output format
   (PDF/DOCX/PPTX), deadline, required template or campus guideline (pedoman), data and sources provided.
   Ask what is missing and matters with the grill-me tool (`.agents/knowledge/grill-me.md`), for example:
   - Format: PDF (Rekomendasi: rapi dan final) / DOCX (bisa diedit) / keduanya
   - Gaya: laporan / akademik / mengikuti template Word dari kampus/kantor (`--ref`)
   Do not ask about things you can decide with the defaults in `documents.md`.
2. **Outline.** Use the structure for the type in `writing.md` §5. Write the headings with one sentence each saying
   the point of that section. For documents over ~5 pages, or slides, show the outline and get a yes first.
3. **Draft** `docs/<name>.md`: front matter (title, author, date, `lang`, `docstyle`), then section by section.
   Topic sentence first in every paragraph; concrete numbers; tables for data, each introduced and interpreted.
   Style references: `.agents/templates/documents/contoh.md` and `contoh-slides.md`. Academic work with citations:
   follow `.agents/skills/wf-research/SKILL.md` for the sources (search, read, note cards) and start from
   `.agents/templates/documents/penelitian/` (proposal.md, artikel.md); citation style: ask, default APA 7
   (`documents.md` → Citations).
4. **Revise.** Read only the topic sentences; fix the story. Check numbers and terms are consistent everywhere.
5. **Check:** `node .agents/scripts/doc-check.mjs docs/<name>.md`. Fix every error and every warning that is real.
   Document with citations: also `node .agents/scripts/cite-check.mjs docs/<name>.md` (no errors allowed).
6. **Build and look:** `node .agents/scripts/doc-build.mjs docs/<name>.md --to <pdf|docx|all> --preview`.
   Open every PNG in the preview folder and run the checklist in `documents.md` → "Verify before you say it is done".
   Fix the source and rebuild until it is clean. Exit code 3 means doc-check errors: not deliverable.
7. **Deliver:** output paths, page count, what was verified, what you assumed, and open `[perlu ...]` items if the user
   chose to keep a draft.

## B. Edit an existing file
1. Find out where it came from. Built by the kit (a `.md` source exists)? Edit the source, rebuild, re-check. Done.
2. Otherwise **preserve the original formatting** (`documents.md` → "Editing existing files"):
   - small text changes in DOCX/PPTX: edit in place (python-docx / python-pptx, or the XML inside the zip);
   - heavy rewrite: ask first; then convert to Markdown, rewrite, rebuild with `--ref original.docx`, compare previews;
   - PDF: find the source; if there is none, extract the text and rebuild as a new document after telling the user
     the layout will change. Merge/split/rotate with pypdf or qpdf.
3. Save as a new file (`<name>-revisi.<ext>`) unless the user said to overwrite.
4. Render the result (`doc-build` preview, or Office/LibreOffice → PDF → PNG) and compare with the original: nothing
   else may have changed (fonts, numbering, headers, images).
5. Report exactly what changed (section, old → new for key sentences or numbers).

## C. Convert / extract
- Reading a PDF/DOCX/PPTX to quote, summarize or take numbers from it: `python .agents/scripts/read-doc.py <file>`
  and follow `.agents/knowledge/reading.md` (page markers, formulas, tables, figures, tracked changes, speaker notes).
- Plain conversion only: `pandoc in.docx -t gfm -o out.md --extract-media=media` (also .pptx, .xlsx).
  Scanned PDF without text: read-doc flags it; OCR needs Docling or a vision model (reading.md section 1).
- Markdown → PDF/DOCX/PPTX: mode A from step 5.
- After converting, open the result and check tables, images and headings survived. Report what was lost.

## D. Review / rewrite
1. Run `doc-check` on the text (save it as `.md` first if needed) and read it as the intended reader.
2. Give the findings grouped by importance: content and logic first (missing support, unclear point, wrong
   structure), then style (slop patterns, bullets that should be paragraphs), then spelling (EYD).
3. Rewrite only when asked. Keep the author's meaning, facts and voice; do not add claims. Show key before → after
   passages for the user to approve when the text is theirs (skripsi, articles).
4. **Academic integrity:** helping the user write, structure and polish is fine. Do not fabricate data, results or
   references, and do not disguise someone else's text as original.

## Finish
- Save the handoff (`wf-handoff`, Save mode) if the document work spans several sessions.
- Report per `AGENTS.md` §6 with the output paths and the preview folder. Verifikasi: doc-check result, build exit
  code, pages viewed.
