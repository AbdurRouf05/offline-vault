---
key: <bibtex key, same as research/refs.bib and the file name>
status: abstract-only     # read-full | read-partial | abstract-only  (only read-full can be cited for claims)
pages_read: ""            # read-partial: e.g. "1-8, 12"; read-full: "all"
page_numbers: printed     # printed (journal page numbers exist) | pdf (no printed numbers; p. = pdf page)
type: <journal article | conference paper | book | chapter | report | thesis | preprint | dataset>
journal_check: ""         # e.g. "SINTA 2 (accredited 2021-2026)", "Scopus Q2 2023 (Scimago)", "DOAJ", "FAILED: <why>"
read_with: ""             # read-doc output folder + engine, e.g. "research/text/<key>, pymupdf + docling"
date_read: YYYY-MM-DD
---

# <Short title> (<First author> <year>)

<!-- Copy to research/notes/<key>.md (wf-research Phase 5). Fill it WHILE reading, a few pages at a time.
     Quote lines MUST look exactly like:  > "exact text copied from text.md" (p. 233; pdf 4)
     cite-check.mjs searches every such quote in research/text/<key>/text.md and fails if it is not there.
     Lines that start with ">" but are not quotes in that format are ignored by cite-check. -->

## Reference

<Authors (year). Title. Journal, volume(issue), pages. DOI> (copy from refs.bib, do not retype from memory)

## Summary per section

- Introduction (p. 1-2): <what the authors say, in your own words>
- Method (p. 3-5): <design, sample, place, period, instruments, analysis>
- Results (p. 6-9): <main results with numbers>
- Discussion / conclusion (p. 10-11): <...>
- Limitations stated by the authors (p. 11): <...>

## Key numbers

| What | Value | Where (table / figure / page) | Verified on page PNG |
|---|---|---|---|
| <sample size> | <n = 120> | <Table 1, p. 5; pdf 3> | <yes / no vision: belum diverifikasi> |

## Quotes I may use

<!-- One quote per line, copied character for character from research/text/<key>/text.md. -->

## Formulas and symbols

<!-- Formula source: docling.md, the crop pages/pNNN-mK.png, or "belum diverifikasi - perlu model yang bisa membaca gambar". -->

| Formula | Source | Status |
|---|---|---|
| <$W_q = \frac{\lambda}{\mu(\mu-\lambda)}$ (Eq. 3, p. 5; pdf 3)> | <docling.md + crop p003-m1.png> | <verified> |

| Symbol | Meaning | Unit | Defined on |
|---|---|---|---|
| <$\lambda$> | <arrival rate> | <customers/hour> | <p. 4> |

## Flagged pages handled

- <pdf 3: 2 formulas - from docling.md, checked on crops>
- <pdf 7: chart - described from caption only (no vision), values not used>

## Teach-back

<!-- 5-8 lines written without looking, then checked line by line against the text. -->

1. Question: <...>
2. Method: <...>
3. Findings: <...>
4. Limitations: <...>
5. Relation to our research question(s): <supports RQ1 because ... / contradicts ... / method to borrow ...>

## Use in the manuscript

- <claim I will make> - <section of this note that supports it>
