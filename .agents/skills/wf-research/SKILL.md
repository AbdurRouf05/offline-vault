---
name: wf-research
description: Research and academic writing with real, read, correctly cited sources - penelitian, skripsi, tesis, proposal, artikel jurnal, literature review, makalah with references. Searches several scholarly databases, downloads legal open-access PDFs into the project, reads PDF/DOCX/PPTX precisely (formulas, tables, figures), keeps a note card per source, collects official data, writes with Mendeley-style citations (APA 7 default) and checks every citation against the source. Use when the user asks to find journals/papers/data, write a research text with citations, or build a reference list.
---

# wf-research: find, read, cite, and write without inventing anything

Three things make research by a weak model trustworthy, and this skill enforces all three:

1. **Files are the memory.** Every search, paper, quote and decision is written in `research/`. Nothing lives only in
   the chat (the model may change between messages).
2. **Cite only what was read.** A source is cited only after its full text was read with `read-doc.py` and a note
   card says `status: read-full`. Abstracts are for screening, never for claims.
3. **Scripts check the work.** `cite-check.mjs` fails when a citation has no source, no note card, or a quote that is
   not in the source text. You do not deliver while it fails.

Talk to the user in Bahasa Indonesia. Kit files and notes are English unless the user's document language is
Indonesian (the manuscript itself follows the user's language, usually Indonesian).

## Ground rules (read twice)

- **Never invent** a paper, author, year, DOI, page, quote, number, or dataset. Missing → `[perlu sumber]` /
  `[perlu data]` in the text and a question to the user. doc-check blocks delivery while these remain.
- **No pirate sites.** Sci-Hub, LibGen, Z-Library, Anna's Archive and similar are illegal. Never download from them,
  never give their links or access tips. Say so plainly if asked, and give the legal routes
  (`.agents/knowledge/research-sources.md` section 6).
- **Legal copies only.** `lit-fetch.mjs` downloads open-access copies; paywalled papers go to
  `research/to-download.md` and the user fetches them legally into `research/inbox/`.
- **Campus rules beat this file** (minimum SINTA rank, Scopus, years, number of references, citation style). Ask
  for them in Phase 1 and write them in `research/RESEARCH.md`.
- **Change check** (AGENTS.md rule 12): when the user later asks for something that contradicts `RESEARCH.md`
  (other topic, other years, other style, a source that failed the quality check), ask with the change check in
  `.agents/knowledge/grill-me.md` before doing it, then record the decision in RESEARCH.md.
- **Academic integrity.** You help find, read, organize and write. You never fabricate data or results, never
  disguise copied text as the user's own, and keep every paraphrase cited. Long verbatim copying is not allowed:
  quote short passages in quotation marks with a page.
- **Keys and email** only in environment variables (`RESEARCH_EMAIL`, `OPENALEX_API_KEY`, `S2_API_KEY`). Never in
  files, never invented.

## Folder layout (create what is missing)

```
research/
  RESEARCH.md         brief: question, scope, criteria, campus rules, style, decisions   (template: RESEARCH.md)
  SEARCH-LOG.md       every search: date, database, query, filters, hits, kept          (written by lit-search)
  search/             lit-search results (.md for reading, .json for lit-fetch)
  inbox/              the USER drops legally obtained PDFs here
  sources/            PDFs, named <key>.pdf (written by lit-fetch)
  refs.bib            BibTeX of every source (written by lit-fetch; do not hand-type entries)
  library.md          table of sources and their PDF status (written by lit-fetch)
  to-download.md      paywalled papers with legal ways to get them (written by lit-fetch)
  text/<key>/         read-doc output: text.md, report.md, pages/*.png, tables/, images/
  notes/<key>.md      one note card per source                                          (template: NOTE.md)
  MATRIX.md           synthesis table: source x method x findings x themes             (template: MATRIX.md)
  data/
    DATA.md           every dataset: source, URL, access date, license, changes        (template: DATA.md)
    raw/              downloaded data, never edited
    processed/        cleaned data, made only by scripts
    scripts/          fetch and clean scripts (re-runnable)
docs/<name>.md        the manuscript (proposal, skripsi chapter, article) built with wf-docs
```

Templates live in `.agents/templates/research/` (RESEARCH, NOTE, MATRIX, DATA, SEARCH-LOG) and
`.agents/templates/documents/penelitian/` (proposal.md, artikel.md).

## Phase 0: setup check (once per laptop, a minute)

1. `node .agents/scripts/tools-check.mjs --for research`. Needed: Node, Python 3 + `pymupdf`; for DOCX: Pandoc;
   for PPTX: `python-pptx`; optional: Docling (formulas as LaTeX, OCR).
2. If `docs/PROJECT.md` → `## Tools setup` exists, follow it. Otherwise ask ONCE (grill-me, options in
   `.agents/knowledge/reading.md` section 1), record the answer there, and install in the background with a log file.
   You can continue with Phases 1-3 while it installs.
3. Ask (grill-me) whether the PDFs may go into git:
   - "Tidak, simpan lokal saja (Recommended)": add `research/sources/`, `research/inbox/`, `research/text/` to
     `.gitignore`. Papers are copyrighted; a public repo must not carry them. They stay on the laptop, and
     `lit-fetch` / `read-doc` can recreate them.
   - "Ya, repo privat": commit them (fine for a private repo; never make it public later without removing them).
4. Email and keys: ask if the user wants to give an email for Unpaywall and the Crossref polite pool (more legal
   PDFs found). They set it themselves: `setx RESEARCH_EMAIL "..."` (Windows, then reopen the terminal) or
   `export RESEARCH_EMAIL=...` in their shell profile. OpenAlex key (free, more daily searches): the user creates it
   at https://openalex.org/settings/api and sets `OPENALEX_API_KEY`. Semantic Scholar key: `S2_API_KEY`
   (https://www.semanticscholar.org/product/api). All optional; the scripts work without them, with less.

## Phase 1: brief (grill the user, then write RESEARCH.md)

Copy `.agents/templates/research/RESEARCH.md` to `research/RESEARCH.md` and fill it with the user. Ask with the
grill-me tool, a few questions at a time, recommendation first, only what you cannot decide yourself:

- **Output**: proposal / skripsi bab 1-3 / skripsi lengkap / artikel jurnal / literature review / makalah.
- **Topic and research question(s)** (rumusan masalah). Help sharpen a vague topic into 1-3 answerable questions;
  for quantitative work also the variables and hypotheses. Show the questions and get a yes.
- **Method** if known: kuantitatif / kualitatif / mixed / systematic literature review / R&D / studi kasus.
- **Campus rules**: minimum journal level (e.g. SINTA 2 / Scopus Q3), years ("10 tahun terakhir"), minimum number
  of references, share of journals vs books, banned source types (Wikipedia, blogs, skripsi), template/pedoman file.
- **Citation style. Always ask, even though there is a default.** Options:
  APA 7 (Recommended, default) / IEEE / Harvard / Chicago author-date / MLA / Vancouver / AMA / APA 6 /
  "Gaya kampus lain" (ask for the .csl file or the guideline). Record it as the `csl:` value
  (`apa`, `ieee`, `harvard-cite-them-right`, `chicago-author-date`, `modern-language-association`,
  `elsevier-vancouver`, `american-medical-association`, `apa-6th-edition`).
- **Languages of sources**: Indonesian and English (Recommended) / English only / Indonesian only.
- **Data**: does the research need data (official statistics, a dataset, a questionnaire the user runs)?
- **Deadline and length.**

Write the inclusion and exclusion criteria from these answers (topic, years, languages, document types, quality
level). They are used in Phase 3, and they make the search reproducible (the "Metode" section of a literature review
needs them).

## Phase 2: search

1. Make 2-4 search strings per research question: main concept + synonyms, in English and Indonesian if both
   languages are allowed. Example: `"queueing model" puskesmas`, `antrean "pelayanan kesehatan"`,
   `"waiting time" "primary health care" simulation`. Write them in RESEARCH.md.
2. Run each string:
   ```
   node .agents/scripts/lit-search.mjs "<string>" --from 2016 --to 2026 --limit 25
   ```
   Useful options: `--oa` (only free full text), `--lang id` (Indonesian papers, OpenAlex), `--preprints` (adds arXiv),
   `--sort citations`, `--sources openalex,crossref,s2,arxiv`. Results go to `research/search/<date>-<slug>.md` and
   `.json`, and a line in `research/SEARCH-LOG.md`. An `error (HTTP 429 ...)` for a source means it is rate-limited:
   continue with the others and tell the user about the free key (Phase 0).
3. The script prints **manual links** (Google Scholar, Garuda, SINTA, DOAJ, Scopus). These sites block scripts, so
   give the links to the user and ask them to paste promising titles or DOIs back. Never scrape Google Scholar.
4. Read `research/search/*.md` (the table and the abstracts). Do not open every paper yet.
5. Also find papers by **snowballing** from the best 2-3 papers once read: their reference list (backward) and
   "cited by" (forward, via Google Scholar or OpenAlex). Log these searches too.
6. Stop searching when new searches return mostly papers you have already seen. Record the totals in SEARCH-LOG.md.

## Phase 3: screening and quality

For each candidate, in this order (details: `.agents/knowledge/research-sources.md` sections 3 and 4):

1. **Title + abstract** match the criteria? No → excluded, with a one-word reason in SEARCH-LOG.md (topic, year,
   language, type).
2. **Not retracted** (`RETRACTED` flag in the results). Retracted → excluded.
3. **Journal check** against the campus rule: SINTA rank (user checks sinta.kemdiktisaintek.go.id), Scopus /
   Scimago quartile, DOAJ, predatory and hijacked signs. A doubtful journal is not silently dropped and not silently
   used: tell the user and let them choose.
4. **Peer reviewed**, or a preprint the user allowed.

Show the user the shortlist as a table (key info, why kept) and get a yes before downloading many papers. Keep counts
for the literature-review flow (found, after duplicates, screened, full text read, included): SEARCH-LOG.md has the
fields.

## Phase 4: get the papers

1. From the search results (numbers from the `#` column):
   ```
   node .agents/scripts/lit-fetch.mjs --search research/search/<file>.json --pick 1,4,7
   ```
   or by DOI / arXiv id: `node .agents/scripts/lit-fetch.mjs 10.1016/j.xxx 2301.01234`.
2. Read the output lines:
   - `pdf` = legal PDF saved to `research/sources/<key>.pdf` and verified (it is the right paper);
   - `pdf-check` = a PDF was saved as `<key>.CHECK.pdf` but may be the WRONG paper: open its first page
     (`read-doc.py --probe`) and compare title and authors. Right → rename to `<key>.pdf`. Wrong → delete it and
     treat as to-download;
   - `todo` = paywalled, listed in `research/to-download.md`.
3. Tell the user which papers are in to-download.md and the legal routes listed there (campus login, Perpusnas,
   the author's own copy, asking the author). They save the PDFs into `research/inbox/` (any file name) and tell you.
4. Then: `node .agents/scripts/lit-fetch.mjs --inbox`. It finds each DOI, adds the entry, moves the file. A file
   without a DOI prints `ASK`: ask the user which paper it is (or find the DOI), then run
   `node .agents/scripts/lit-fetch.mjs <doi> --file "research/inbox/<file>.pdf"`.
5. Books, regulations, reports without a DOI: ask the user for the details (or read them from the document's
   first pages) and add the BibTeX entry by hand following the same style as lit-fetch (key `familyYEARword`,
   `title = {{...}}`, plus `url` and `urldate` for web documents). Mark it `% added by hand` above the entry.
6. Never edit a lit-fetch entry by guessing. Wrong metadata (author missing, title in capitals): fix it from the
   PDF's first page and note the fix in the note card.

## Phase 5: read each source precisely

Follow `.agents/knowledge/reading.md` for every source. In short:

1. `python .agents/scripts/read-doc.py research/sources/<key>.pdf --key <key>` (DOCX/PPTX work the same way).
2. Read `research/text/<key>/report.md` first; check that the DOI is the one in refs.bib.
3. Copy `.agents/templates/research/NOTE.md` to `research/notes/<key>.md`. Read text.md in chunks of 3-5 pages and
   fill the note card AS YOU GO: summary per section with pages, exact quotes as `> "..." (p. N; pdf M)`, numbers
   with table/figure numbers, symbol table for formulas.
4. Handle every flagged page (formulas, tables, figures, scans) as reading.md section 4 says. Cannot see images?
   Write "belum diverifikasi" and tell the user which pages need a vision model or a manual check.
5. Set `status:` honestly: `read-full` only if you read every page of the main text. `read-partial` +
   `pages_read:` otherwise. `abstract-only` sources cannot be cited for findings.
6. Teach-back at the end of the card (reading.md section 7), checked against the text.
7. One source per step. After each source, add its row to `research/MATRIX.md` and save the handoff if the chat is
   long (`wf-handoff`). Do not read ten papers and then write ten cards from memory.

## Phase 6: data (when the research needs it)

1. Find official sources first (`.agents/knowledge/research-sources.md` section 5): BPS, Satu Data, BI, OJK, IDX,
   ministries, World Bank, etc. Tell the user which table/series and why.
2. Download by script into `research/data/raw/` (official API or download URL), the script in
   `research/data/scripts/`. A site that needs a login or forbids scripts: ask the user to download and put the file
   in `raw/`.
3. Clean with a script into `research/data/processed/`. Never edit raw files or type numbers by hand.
4. Record each dataset in `research/data/DATA.md` (template `DATA.md`): source, exact table name, URL, access date,
   license, unit, period, what the scripts changed.
5. Cite datasets in the text like other sources (a `@misc` or `@dataset` entry with `url` and `urldate`, author =
   the agency, for example `author = {{Badan Pusat Statistik}}`).
6. Questionnaires and interviews: the instrument goes in `research/data/instrument/`; personal data stays out of
   git; follow the campus ethics process (`research-sources.md` section 5).

## Phase 7: synthesize

1. Read across the note cards and MATRIX.md. Group the sources by **theme** (what they say about each part of the
   research question), not by paper. Note where sources agree, disagree, and what nobody has studied yet (the gap
   that justifies the user's research).
2. Write an outline for the manuscript section with, under each heading, the claims you will make and the keys that
   support each claim. Every claim needs at least one read-full source; claims from the user's own data need the
   analysis in `research/data/`.
3. Show the outline to the user (it is the plan; rule 3) and get a yes.

## Phase 8: write

Follow `.agents/skills/wf-docs/SKILL.md` and `.agents/knowledge/writing.md` (paragraph-first, Indonesian EYD).

1. Start from `.agents/templates/documents/penelitian/proposal.md` or `artikel.md` (copy to `docs/<name>.md`). Set
   in the front matter: `bibliography: ../research/refs.bib`, `csl: <style from RESEARCH.md>`, `lang: id`,
   `docstyle: akademik`.
2. Cite with keys from refs.bib only: `[@key]`, `@key` (narrative), `[@key, hlm. 12]`, `[@a; @b]`. The reference
   list is generated (`::: {#refs}`); never type it.
3. Paraphrase in your own words and cite. Use a direct quote only when the exact words matter: short, in quotation
   marks, with the page: `"..." [@key, hlm. 12]`, copied from the note card.
4. Every number from a source carries a citation; every number from the user's data points to the table or figure
   made from `research/data/processed/`.
5. Do not write the same claim from memory "because it is well known". If it is worth saying, cite a read source;
   if no source was read, write `[perlu sumber]` and add it to the search list.
6. Do not cite a source for something it does not say. Before citing, look at the note card line you are using.

## Phase 9: check and build

1. `node .agents/scripts/cite-check.mjs docs/<name>.md`. Fix every ERROR:
   - E1 key not in refs.bib → wrong key, or the source was never added (lit-fetch it, then read it);
   - E2 no note card / E3 not read-full → read the source (Phase 5) or remove the citation;
   - E4/E5 quote not in the source → copy it again from text.md, or remove it;
   - E6 duplicate key → merge the entries.
   Warnings: read each one; "never cited" entries are fine if intentional.
2. `node .agents/scripts/doc-check.mjs docs/<name>.md` (prose, `[perlu ...]` markers, structure).
3. `node .agents/scripts/doc-build.mjs docs/<name>.md --to docx --preview` (or `pdf` / `all`). Open every preview
   page: citations show as (Name, year) in the chosen style, the reference list is complete and sorted, Indonesian
   labels (dkk.) are right, tables and formulas look right.
4. Check the campus rules from RESEARCH.md: number of references, years, journal level. Report any shortfall.

## Phase 10: hand over

1. Save the handoff (`wf-handoff`, Save mode) with: research question, sources read / to read, to-download items
   waiting for the user, open `[perlu ...]` markers.
2. Report to the user (AGENTS.md §6), in Bahasa Indonesia: output files; number of sources found, read, cited;
   cite-check and doc-check results; items still waiting for the user (to-download, pages needing a vision check,
   doubtful journals, data to download); how citations behave in Word (one click selects the citation, Ctrl+click
   jumps to the reference).

## Small tasks inside this skill

- "Carikan jurnal tentang X" only: Phases 1 (short: topic, years, languages, level) → 2 → 3, deliver the shortlist
  with the journal check. Ask before downloading.
- "Baca PDF ini dan rangkum": Phase 5 only, deliver the note card. Summaries cite pages.
- "Rapikan daftar pustaka saya": get the DOIs from the user's list, `lit-fetch.mjs <doi> ... --no-pdf`, convert the
  manuscript citations to `[@key]`, build with the chosen style. Entries without DOI: by hand, checked.
- "Cek sitasi skripsi saya" (a DOCX from the user): read it with read-doc.py, list each citation and reference,
  check that every in-text citation has a reference entry and vice versa, check years and names match, check
  formatting against the chosen style. Report; change the file only when asked (`-revisi` copy, wf-docs mode B).
