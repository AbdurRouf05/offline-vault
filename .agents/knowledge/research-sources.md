# Research sources: where to find papers and data, what is reputable, what is legal

Read this before searching (wf-research Phase 2) and before deciding whether a paper may be cited (Phase 3).
Words used below:

- **Index / database**: a list of papers with metadata (title, authors, journal, DOI). Some are curated (a team
  decides which journals get in), others take everything.
- **Curated** = a journal had to pass checks to be listed. Being in a curated index is a quality signal, not a guarantee.
- **OA (open access)** = free to read legally. **Paywalled** = you must pay or have campus access.
- **Peer reviewed** = checked by other experts before publication. Preprints are NOT peer reviewed.

## 1. The short answer for Indonesian students

1. Ask the user for their campus rules first (grill, wf-research Phase 1). Common rules: "minimal jurnal SINTA 2 / Scopus",
   "referensi 5 atau 10 tahun terakhir", "minimal 80% dari jurnal", "tidak boleh mengutip Wikipedia / blog / skripsi".
   The campus rule beats this file.
2. Search with `lit-search.mjs` (OpenAlex + Crossref + Semantic Scholar, optional arXiv). Give the user the manual
   links it prints for Google Scholar, Garuda, and SINTA.
3. Before citing a paper, check its journal with section 4 below ("Is this journal OK?").
4. Get the PDF only by the legal routes in section 6.

## 2. Journal databases and search engines

"Official" = run by the index owner, a government body, or a recognized non-profit. "Use for citing" = a paper found
here can be cited if the journal passes section 4. "Discovery only" = a good place to find papers, but being listed
there says nothing about quality.

### Curated indexes (quality signal)

| Name | Who runs it | Official | Cost | How the AI uses it | Notes |
|---|---|---|---|---|---|
| Scopus | Elsevier | yes | campus subscription to search; journal list free | user searches via campus login; AI checks a journal at scopus.com/sources | Indonesia's main "reputable international" bar (for lecturers' credit points and many campus rules). Has a list of **discontinued** journals: papers published after the discontinuation date do not count as Scopus. |
| Web of Science (SCIE, SSCI, AHCI, ESCI) | Clarivate | yes | subscription; Master Journal List free (mjl.clarivate.com) | check a journal in the Master Journal List | Stricter than Scopus. The Impact Factor (JIF) is only in JCR (paid). ESCI journals have no JIF quartile from Clarivate before 2023-style editions; check the current JCR rules if the user needs it. |
| SINTA | Kemdiktisaintek (Indonesian ministry) | yes | free | the user opens sinta.kemdiktisaintek.go.id (it blocks bots); the AI asks the user to paste the journal's rank | Accreditation of Indonesian journals **S1 (highest) to S6**, given through the Arjuna system. Accreditation has a **validity period**: check that the article's year falls inside it. |
| DOAJ | Directory of Open Access Journals (non-profit) | yes | free, API | `lit-search` marks DOAJ journals | Only OA journals that passed DOAJ's checks. Not listed does not mean bad (many good subscription journals are not OA). |
| PubMed / PMC / Europe PMC | US NLM / EMBL-EBI | yes | free, API | search for medicine, health, biology | MEDLINE-indexed journals are curated. PMC has free full texts. |
| ERIC | US Department of Education | yes | free, API | search for education topics | Has a "peer reviewed only" filter. |

### Open catalogs and search engines (discovery)

| Name | Who runs it | Official | Cost | How the AI uses it | Notes |
|---|---|---|---|---|---|
| OpenAlex | OurResearch (non-profit) | yes (open catalog) | free API; without a key a small daily budget shared per IP, free key for more (`OPENALEX_API_KEY`) | `lit-search` default source | Very broad (takes everything, including predatory journals). Good metadata: OA status, citations, retractions, Indonesian journals too. Sometimes merges two works by mistake: `lit-fetch` checks the DOI. |
| Crossref | Crossref (DOI registry, non-profit) | yes | free API (`RESEARCH_EMAIL` for the faster "polite pool") | `lit-search` source; `lit-fetch` metadata via the DOI | Every DOI from member publishers. Metadata quality depends on the publisher. Holds the Retraction Watch data. |
| Semantic Scholar | Allen Institute for AI (non-profit) | yes | free API, key recommended (`S2_API_KEY`); without a key it often answers 429 | `lit-search` source | Good for computer science and biomedicine; has citation context. |
| Google Scholar | Google | yes, but not curated | free; **no API, scraping forbidden** | the AI gives the user a search link; never scrapes | Broadest coverage (theses, slides, predatory journals all mixed in). Useful to find a free version ("All versions", the [PDF] link on the right). Citation counts are inflated. |
| Garuda (Garba Rujukan Digital) | Kemdiktisaintek | yes | free | user opens garuda.kemdiktisaintek.go.id; the AI gives the link | Portal of Indonesian journal articles. Check the journal's SINTA rank separately. |
| Neliti | private (Indonesia) | no (aggregator) | free | discovery of Indonesian papers and policy documents | Cite the original journal, not Neliti. |
| CORE | Open University / Jisc (UK) | yes (non-profit) | free, API key free | find free full texts from repositories | Aggregates OA copies from university repositories worldwide. |
| BASE | Bielefeld University Library | yes | free | find repository copies | Search engine over thousands of repositories. |
| Dimensions (free version), Lens.org | Digital Science / Cambia | yes | free tier | discovery, citation maps | Lens also covers patents. |
| Connected Papers, ResearchRabbit, Litmaps | private | no | free tiers | the user explores citation graphs from one key paper | Good for finding related work; check every paper they show. |
| Elicit, Consensus, other AI search tools | private | no | free tiers | discovery only | They can misstate findings. Never cite from their summaries; open and read the paper. |

### Preprint servers (not peer reviewed)

arXiv (physics, math, computer science, statistics, economics), bioRxiv and medRxiv (biology, medicine), SSRN (economics,
law, social sciences), RePEc / IDEAS (economics), OSF Preprints, Preprints.org, Research Square. Rules:

- A preprint may be cited only if the user's field accepts it (computer science often does; most skripsi guides prefer
  published papers). Mark it "preprint" in the note card.
- Before citing, check if a peer-reviewed version exists (search the title in Crossref/OpenAlex). If yes, cite and read
  that one.

### Publisher platforms (where the paper actually lives)

ScienceDirect (Elsevier), SpringerLink, Wiley Online Library, Taylor & Francis Online, SAGE Journals, IEEE Xplore,
ACM Digital Library, Emerald Insight, Oxford Academic, Cambridge Core, JSTOR (archive, humanities/social sciences),
and OA publishers (PLOS, Frontiers, MDPI, BMC, Hindawi). Big publishers have both excellent and weak journals: judge the
journal, not the publisher. Hindawi (Wiley) had mass retractions in 2023 from paper mills, and some MDPI journals are
debated. For these, check the journal's Scopus status and quartile, and its retraction count.

### Other places, with care

| Source | Use | Care |
|---|---|---|
| ResearchGate, Academia.edu | read a copy the author uploaded; ask the author for the full text | cite the published version (journal + DOI), never the ResearchGate page |
| Campus repositories (skripsi, tesis, disertasi) | discover local studies, methods, questionnaires | grey literature, not peer reviewed; many campuses limit or forbid citing skripsi. Ask the user. |
| Books: Google Books (preview), DOAB and OAPEN (free OA books), iPusnas (Perpusnas e-book app), campus library | theory chapters, definitions | cite the edition you read, with page numbers |
| Wikipedia, blogs, news | background only, find leads | do not cite as a scholarly source (unless the topic is the news itself) |
| Government reports, regulations (UU, PP, Permen), WHO/World Bank reports | official facts, policy | cite them; they are primary sources for policy and statistics |

## 3. Picking papers (screening) in order

1. Title and abstract fit the research question (wf-research Phase 3 criteria: topic, population, years, language, type).
2. Not retracted (`lit-search` prints RETRACTED; you can also check retractiondatabase.org or the publisher page).
3. The journal passes section 4.
4. Peer reviewed (or a preprint explicitly allowed by the user).
5. Full text obtainable legally (section 6). A paper you can only see the abstract of may NOT be cited for its
   findings (kit rule: cite only what you read in full).

## 4. Is this journal OK?

Check the journal of every paper you plan to cite. Write the result in the note card (`journal_check:`).

1. **Indonesian journal**: SINTA rank and accreditation period. The user opens SINTA and pastes the result if the AI
   cannot open it. Compare with the campus minimum.
2. **International journal**: is it in Scopus (scopus.com/sources, also check the discontinued list) or Web of Science
   (Master Journal List)? Quartile: Scimago (scimagojr.com, free, based on Scopus data). Quartiles differ per subject
   category and year; use the year the paper was published and the category of the topic.
3. **Hijacked journal check**: open the journal website from the Scopus/SINTA source page itself, not from a Google
   result or an email. Hijackers clone the site of a real journal on a similar domain. Retraction Watch keeps a Hijacked
   Journal Checker.
4. **Predatory signs** (two or more signs: do not cite, tell the user why):
   - promises publication in days, or accepts almost everything for a fee (APC) with no real review;
   - very broad scope ("International Journal of Science, Engineering and Technology");
   - claims fake metrics: "Global Impact Factor", "Index Copernicus Value", "SJIF", "Universal Impact Factor";
     only Clarivate's JIF and Scopus's CiteScore/SJR are real;
   - claims indexing you cannot confirm in the index itself (says "Scopus indexed" but not in scopus.com/sources);
   - editors you cannot find, fake addresses, spam invitations, hundreds of papers per issue;
   - only in Google Scholar, not in Scopus/WoS/DOAJ/SINTA.
   Beall's list is archived and outdated: use it only as a hint. The checklist at thinkchecksubmit.org is a good aid.
5. **Retractions and corrections**: retracted paper = never cite (except when writing about the retraction).
   Corrected paper = cite it, read the correction.

When a paper fails the check but is important, tell the user plainly and let them decide (grill). Never hide it.

## 5. Data sources

Use official data first. Record every dataset in `research/data/DATA.md` (source, URL, date accessed, license, what
was changed). Raw files go in `research/data/raw/` and are never edited; cleaned files go in `research/data/processed/`
and are made by a script (`research/data/scripts/`), so every number can be traced back.

### Indonesia

| Source | What | Access |
|---|---|---|
| BPS (bps.go.id) | official statistics: population, poverty, inflation, labor, regional data ("Dalam Angka" books per province/regency) | free tables and PDFs; Web API with a free key (webapi.bps.go.id); microdata (Susenas, Sakernas) by request, often paid |
| Satu Data Indonesia (data.go.id) and regional open-data portals | government open datasets | free download |
| Bank Indonesia (bi.go.id) | SEKI (economic and financial statistics), interest rates, exchange rates | free tables |
| OJK (ojk.go.id) | banking, insurance, fintech, capital-market statistics | free reports and tables |
| IDX (idx.co.id) | listed companies: financial statements, annual reports, prices | free (reports per company) |
| Kemenkes | Profil Kesehatan Indonesia (yearly), national health survey reports (Riskesdas 2018, SKI 2023) | free PDFs |
| Other ministries (education, agriculture, trade) | sector statistics | check the ministry site's "data" or "statistik" page |
| IFLS (Indonesia Family Life Survey, RAND) | household panel survey | free with registration |

### International

World Bank Open Data (free API), IMF Data, OECD Data Explorer, UNdata, WHO Global Health Observatory, ILOSTAT, FAOSTAT,
Penn World Table. Our World in Data is a good aggregator: cite the original source it names, or both.

### Repositories and search

Google Dataset Search, Zenodo, Figshare, Harvard Dataverse, Mendeley Data, ICPSR, UCI Machine Learning Repository,
Kaggle. Kaggle and other user uploads: check who made the data, where it came from, and the license before using it.
If the origin is unclear, tell the user it is weak evidence.

### Primary data (questionnaire, interview, observation)

Informed consent, anonymize names, store raw responses outside git if they contain personal data, follow the campus
ethics process. Indonesian personal-data law applies (UU No. 27/2022 tentang Pelindungan Data Pribadi).

### Getting data by script

- Prefer the official API or the download button. Write the fetch in `research/data/scripts/` so it can be re-run.
- Scraping a website: read its robots.txt and terms first, go slow (one request every few seconds), never scrape
  behind a login, never collect personal data, and cite the site with the access date. If the terms forbid it, ask
  the user to download manually.

## 6. Getting full texts legally

In this order (lit-fetch does 1-3 automatically, the rest is listed in `research/to-download.md` for the user):

1. Open-access copy from the publisher (gold / hybrid / diamond / bronze OA).
2. Repository copy (green OA): arXiv, PMC, Zenodo, university repositories, found via OpenAlex and Unpaywall
   (Unpaywall needs `RESEARCH_EMAIL`, the user's own email; ask them).
3. Preprint of the same paper (read it, but check the published version for changes before citing numbers).
4. The DOI page in a normal browser: some publishers show the PDF to readers but block scripts.
5. Google Scholar "All versions" / the [PDF] link: often the author's own copy.
6. Ask the author: the corresponding author's email on the publisher page, or "Request full-text" on ResearchGate.
   Authors are usually happy to share.
7. Campus library: e-journal subscriptions through the campus login (ScienceDirect, SpringerLink, ProQuest, EBSCO...).
8. Perpusnas e-resources (e-resources.perpusnas.go.id): free membership for Indonesian citizens, gives access to
   several international databases (the list changes; check the site).
9. Interlibrary loan / document delivery through the campus library.

The user saves the PDF into `research/inbox/` and says so; the AI runs `node .agents/scripts/lit-fetch.mjs --inbox`.

### Pirate sites: not used, not linked

Sci-Hub, LibGen, Z-Library, Anna's Archive and similar sites distribute copyrighted papers without permission. They are
illegal under copyright law, and Indonesia's ministry (Komdigi, formerly Kominfo) has blocked several of them. This kit
never downloads from them, never gives links or access instructions, and never suggests workarounds (mirrors, VPN).
When a user asks, answer honestly in Bahasa Indonesia: say that these sites exist and are illegal, that the kit will
not use or link them, and list the legal routes above (routes 5, 6 and 8 often work within a day).

## 7. Keys and the user's email

`RESEARCH_EMAIL`, `OPENALEX_API_KEY`, `S2_API_KEY` are environment variables. Ask the user once, then tell them how to
set it on their machine (Windows PowerShell: `setx RESEARCH_EMAIL "nama@contoh.com"`, then open a new terminal).
Never write the email or a key into a file that goes into git, and never invent an email.
