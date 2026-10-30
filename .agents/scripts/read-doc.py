#!/usr/bin/env python3
"""Workflow Kit - read a PDF, DOCX or PPTX precisely, for an AI that will cite it.

Turns one document into a folder an AI can read in chunks and check against the original:

  <out>/text.md     full text in reading order. PDF: <!-- page N --> markers, two-column pages ordered left then right,
                    hyphenation and ligatures fixed, tables as Markdown, code in ``` fences, formulas marked.
                    DOCX: Pandoc Markdown (equations as $LaTeX$, tracked changes and comments kept).
                    PPTX: <!-- slide N --> markers, titles, text, tables, chart data, speaker notes.
  <out>/report.md   READ THIS FIRST: page index (chars + flags per page) and what still needs a human-quality look:
                    formulas, figures, scanned pages, garbled text, charts. Each flag says which PNG to look at.
  <out>/tables/     each table as .md
  <out>/images/     embedded pictures (PDF/DOCX/PPTX)
  <out>/pages/      PNG renders of flagged pages (or all with --render all), plus close-up crops of formulas
  <out>/meta.json   metadata, DOI candidates, counts
  <out>/docling.md  (optional) Docling's version with formulas as LaTeX and OCR for scans, when Docling is installed

Usage:
  python .agents/scripts/read-doc.py <file> [--out DIR] [--key KEY] [--pages 1-5,9]
                                     [--render flagged|all|none] [--dpi 110] [--engine auto|pymupdf|docling]
  Default --out: research/text/<key>  (key = file name in lower-case-with-dashes)
  --engine auto     PyMuPDF always; Docling too when installed AND the PDF has formulas or scanned pages (only those pages)
  --engine docling  force Docling as well, on --pages or every page (slow: ~1 min per formula on a CPU)
  --engine pymupdf  never run Docling
  --probe           PDF only: print JSON {dois, arxiv, title, pages, first_page} and write nothing (lit-fetch.mjs uses it to
                    find the DOI of a PDF and to check that a downloaded PDF is really the paper it should be)

Needs: pymupdf (PDF), pandoc + python-docx (DOCX), python-pptx (PPTX). Check with: node .agents/scripts/tools-check.mjs --for read
Guide: .agents/knowledge/reading.md (how to read the output so nothing is misread or invented).
Exit: 0 ok, 1 failed, 2 bad usage or missing library.
"""

import argparse
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
from collections import Counter
from datetime import datetime
from pathlib import Path

DOI_RE = re.compile(r'\b(10\.\d{4,9}/[^\s"<>\])]+)', re.I)
MATH_FONT_RE = re.compile(r'CMMI|CMSY|CMEX|CMBSY|MSAM|MSBM|EUFM|EUSM|RSFS|LMMath|Math|Symbol|STIX|MTExtra|Euclid|Mathematica|TeXGyre.*Math|XITS|Asana', re.I)
MONO_FONT_RE = re.compile(r'Mono|Courier|Consola|Menlo|Inconsolata|CMTT|SFTT|LMMono|Typewriter|Fira ?Code|Source ?Code|Lucida ?Console', re.I)
MATH_CHARS = set('∑∏∫∮√∂∇∞≤≥≈≠≡∈∉⊂⊆⊃∪∩∀∃→←↔⇒⇔±×÷·∝∼≃⊕⊗‖⟨⟩αβγδεζηθικλμνξπρστυφχψωΓΔΘΛΞΠΣΦΨΩ')
CAPTION_RE = re.compile(r'^\s*(Figure|Fig\.|Gambar|Grafik|Diagram|Table|Tabel|Chart|Bagan|Algorithm|Algoritma|Listing)\s*[\dIVX]+', re.I)
BULLET_RE = re.compile(r'^\s*([•◦▪‣\-–]|\(?\d{1,2}[.)]|\(?[a-z][.)])\s')


def slug(name):
    s = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
    return s[:60] or 'doc'


def parse_pages(spec, n):
    if not spec:
        return list(range(n))
    out = []
    for part in spec.split(','):
        part = part.strip()
        if '-' in part:
            a, b = part.split('-', 1)
            out.extend(range(int(a) - 1, min(int(b), n)))
        elif part:
            out.append(int(part) - 1)
    return [p for p in sorted(set(out)) if 0 <= p < n]


def find_dois(text):
    seen = []
    for m in DOI_RE.finditer(text or ''):
        d = m.group(1).rstrip('.,;:')
        if d.lower() not in [s.lower() for s in seen]:
            seen.append(d)
    return seen


def md_escape_cell(s):
    return (s or '').strip().replace('|', '\\|').replace('\n', '<br>')


def rows_to_md(rows):
    rows = [[md_escape_cell(c) for c in r] for r in rows if r]
    if not rows:
        return ''
    width = max(len(r) for r in rows)
    rows = [r + [''] * (width - len(r)) for r in rows]
    lines = ['| ' + ' | '.join(rows[0]) + ' |', '|' + '---|' * width]
    lines += ['| ' + ' | '.join(r) + ' |' for r in rows[1:]]
    return '\n'.join(lines)


# ----------------------------------------------------------------------------------------------------------- PDF

def read_pdf(path, out, args):
    try:
        import pymupdf
    except ImportError:
        sys.exit('read-doc: pymupdf is not installed. Run: python -m pip install --user pymupdf')

    doc = pymupdf.open(path)
    if doc.needs_pass:
        sys.exit('read-doc: the PDF is password-protected. Ask the user for an unlocked copy.')
    pages = parse_pages(args.pages, doc.page_count)
    # Ligatures expanded (fi, fl). No TEXT_DEHYPHENATE: it would turn 'rata-' + 'rata' into 'ratarata'; join_prose() decides.
    flags = pymupdf.TEXTFLAGS_DICT & ~pymupdf.TEXT_PRESERVE_LIGATURES & ~pymupdf.TEXT_PRESERVE_IMAGES

    # Pass 1: collect blocks per page and the typical body font size.
    raw = {}
    sizes = []
    margin_texts = Counter()
    for pno in pages:
        page = doc[pno]
        d = page.get_text('dict', flags=flags)
        blocks = [b for b in d['blocks'] if b.get('type') == 0]
        raw[pno] = (page, blocks)
        h = page.rect.height
        for b in blocks:
            for ln in b['lines']:
                for sp in ln['spans']:
                    if sp['text'].strip():
                        sizes.extend([round(sp['size'], 1)] * len(sp['text']))
            y0, y1 = b['bbox'][1], b['bbox'][3]
            if y1 < h * 0.08 or y0 > h * 0.92:
                margin_texts[margin_key(b)] += 1
    body_size = statistics.median(sizes) if sizes else 10
    repeat_min = max(3, int(len(pages) * 0.3))
    repeated = {k for k, c in margin_texts.items() if c >= repeat_min and k}

    md = [f'<!-- source: {path.name} | pages {len(pages)} of {doc.page_count} | engine pymupdf {pymupdf.VersionBind} -->']
    index = []
    all_flags = {}
    counts = Counter()
    first_pages_text = ''

    for pno in pages:
        page, blocks = raw[pno]
        W, H = page.rect.width, page.rect.height
        pflags = []
        md.append(f'\n<!-- page {pno + 1} -->\n')

        # Tables first, so their text is not repeated as prose.
        tables = []
        try:
            for i, t in enumerate(page.find_tables().tables, 1):
                rows = t.extract()
                if not rows or len(rows) < 2 or max(len(r) for r in rows) < 2:
                    continue
                tid = f'p{pno + 1}-t{len(tables) + 1}'
                tmd = rows_to_md([[c or '' for c in r] for r in rows])
                # Borderless tables often come out with several columns squeezed into one cell.
                if any(len(re.findall(r'(?<![\w.])[-+]?\d+(?:[.,]\d+)?%?(?![\w.])', c or '')) >= 3 for r in rows for c in r):
                    pflags.append(f'table {tid}: cells look MERGED (several numbers in one cell) - rebuild this table '
                                  f'from pages/p{pno + 1:03d}.png, do not cite numbers from tables/{tid}.md')
                (out / 'tables').mkdir(exist_ok=True)
                (out / 'tables' / f'{tid}.md').write_text(tmd + '\n', encoding='utf-8')
                tables.append({'bbox': pymupdf.Rect(t.bbox), 'id': tid, 'md': tmd})
        except Exception as e:  # find_tables can fail on odd pages; the page render still shows the table
            pflags.append(f'table detection failed ({type(e).__name__}) - check the page PNG')
        if tables:
            counts['tables'] += len(tables)
            pflags.append(f'{len(tables)} table(s): verify every cell against pages/p{pno + 1:03d}.png before citing numbers')

        items = []
        for t in tables:
            items.append({'bbox': tuple(t['bbox']), 'kind': 'table', 'table': t})
        for b in blocks:
            r = pymupdf.Rect(b['bbox'])
            if any(r.intersect(t['bbox']).get_area() > 0.6 * max(r.get_area(), 1) for t in tables):
                continue
            if margin_key(b) in repeated or is_page_number(b, H):
                continue
            items.append({'bbox': b['bbox'], 'kind': 'text', 'block': b})

        # Embedded pictures (skip tiny icons/logos).
        imgs = []
        try:
            infos = page.get_image_info(xrefs=True)
        except Exception:
            infos = []
        for info in infos:
            bb = pymupdf.Rect(info['bbox'])
            if bb.width < 40 or bb.height < 40 or bb.get_area() < 0.01 * W * H or not info.get('xref'):
                continue
            iid = f'p{pno + 1}-img{len(imgs) + 1}'
            fname = save_pdf_image(doc, info['xref'], out / 'images', iid)
            if fname:
                imgs.append(iid)
                items.append({'bbox': tuple(bb), 'kind': 'image', 'file': fname})
        if imgs:
            counts['images'] += len(imgs)

        # Convert text blocks, then merge pieces of one display formula (PyMuPDF often splits them).
        entries = []
        for it in order_items(items, W):
            if it['kind'] == 'text':
                text, info = block_to_md(it['block'], body_size)
                if not text.strip():
                    continue
                it = {**it, 'text': text, 'info': info}
                prev = entries[-1] if entries else None
                if (info['math'] and prev and prev['kind'] == 'text' and prev['info']['math']
                        and it['bbox'][1] - prev['bbox'][3] < body_size * 1.5):
                    prev['bbox'] = tuple(pymupdf.Rect(prev['bbox']) | pymupdf.Rect(it['bbox']))
                    prev['text'] += '\n' + text
                    continue
            entries.append(it)

        page_text_parts = []
        math_blocks = []
        code_found = caption_found = False
        inline_math = garbled = 0
        for it in entries:
            if it['kind'] == 'table':
                md.append(f"<!-- table {it['table']['id']} (also in tables/{it['table']['id']}.md) -->\n{it['table']['md']}\n")
                continue
            if it['kind'] == 'image':
                md.append(f"![picture](images/{it['file']})\n")
                continue
            text, info = it['text'], it['info']
            garbled += text.count('\ufffd') + text.count('(cid:')
            page_text_parts.append(text)
            if info['code']:
                code_found = True
                md.append('```\n' + text + '\n```\n')
            elif info['math']:
                math_blocks.append(it['bbox'])
                mid = f'p{pno + 1:03d}-m{len(math_blocks)}'
                md.append(f'<!-- formula {mid}: the text below is NOT reliable (symbols, fractions, sub/superscripts are lost); '
                          f'transcribe from pages/{mid}.png -->\n{text}\n<!-- /formula {mid} -->\n')
            else:
                if CAPTION_RE.match(text):
                    caption_found = True
                if info['inline_math']:
                    inline_math += 1
                md.append(text + '\n')

        page_text = '\n'.join(page_text_parts)
        if pno < 2:
            first_pages_text += page_text + '\n'
        chars = len(page_text)

        drawings = 0
        try:
            drawings = len(page.get_drawings())
        except Exception:
            pass
        scanned = chars < 80 and (infos or drawings == 0)
        if scanned:
            pflags.append('almost no text layer (scanned page?) - read pages PNG, or OCR with Docling')
        if garbled:
            pflags.append(f'{garbled} unreadable glyph(s) (font without Unicode map) - read the page PNG for exact wording')
        if math_blocks:
            counts['formulas'] += len(math_blocks)
            pflags.append(f'{len(math_blocks)} formula block(s): transcribe from the crops pages/p{pno + 1:03d}-m*.png')
        if inline_math:
            pflags.append(f'{inline_math} paragraph(s) with inline math: sub/superscripts may be flattened (d_k printed as "dk"), '
                          f'check symbols on pages/p{pno + 1:03d}.png before quoting them')
        if code_found:
            counts['code'] += 1
            pflags.append('code / monospace text in ``` fences: copy verbatim, check indentation on the page PNG')
        if imgs:
            pflags.append(f'{len(imgs)} picture(s) in images/: describe only what you can see, with the caption')
        if drawings > 150 or (caption_found and not imgs and not tables):
            pflags.append('vector figure/chart (not extractable as a picture) - look at the page PNG')

        render = args.render == 'all' or (args.render == 'flagged' and pflags)
        if render:
            (out / 'pages').mkdir(exist_ok=True)
            page.get_pixmap(dpi=args.dpi).save(str(out / 'pages' / f'p{pno + 1:03d}.png'))
            for i, bb in enumerate(math_blocks, 1):
                clip = pymupdf.Rect(bb) + (-6, -4, 6, 4)
                page.get_pixmap(dpi=220, clip=clip & page.rect).save(str(out / 'pages' / f'p{pno + 1:03d}-m{i}.png'))
        if pflags:
            all_flags[pno + 1] = pflags
        index.append((pno + 1, chars, pflags))

    meta = {k: v for k, v in (doc.metadata or {}).items() if v}
    toc = doc.get_toc()
    dois = find_dois(' '.join(meta.values()) + '\n' + first_pages_text)
    result = {
        'source': str(path), 'type': 'pdf', 'pages_total': doc.page_count, 'pages_read': len(pages),
        'metadata': meta, 'doi_candidates': dois, 'counts': dict(counts), 'body_font_size': body_size,
        'removed_repeated_header_footer': sorted(repeated)[:10], 'outline': toc[:60],
    }
    if toc:
        md.insert(1, '<!-- outline (from the PDF bookmarks): ' + ' | '.join(f"{'  ' * (l - 1)}{t} p{p}" for l, t, p in toc[:40]) + ' -->')
    return '\n'.join(md), index, all_flags, result, counts


def margin_key(b):
    t = ' '.join(sp['text'] for ln in b['lines'] for sp in ln['spans']).strip()
    return re.sub(r'\d+', '#', t)[:80]


def is_page_number(b, H):
    t = ' '.join(sp['text'] for ln in b['lines'] for sp in ln['spans']).strip()
    y0, y1 = b['bbox'][1], b['bbox'][3]
    return bool(re.fullmatch(r'(page|hal(aman)?\.?)?\s*[-–]?\s*[\divxlc]{1,5}\s*[-–]?', t, re.I)) and (y1 < H * 0.1 or y0 > H * 0.9)


def order_items(items, W):
    """Reading order for one- and two-column pages: full-width items cut the page into bands;
    inside a band, the whole left column comes before the right column."""
    mid = W / 2

    def side(it):
        x0, x1 = it['bbox'][0], it['bbox'][2]
        if x1 <= mid + W * 0.03:
            return 'L'
        if x0 >= mid - W * 0.03:
            return 'R'
        return 'F'

    items = sorted(items, key=lambda it: (round(it['bbox'][1], 1), it['bbox'][0]))
    out, left, right = [], [], []
    for it in items:
        s = side(it)
        if s == 'F':
            out += sorted(left, key=lambda i: i['bbox'][1]) + sorted(right, key=lambda i: i['bbox'][1])
            left, right = [], []
            out.append(it)
        else:
            (left if s == 'L' else right).append(it)
    return out + sorted(left, key=lambda i: i['bbox'][1]) + sorted(right, key=lambda i: i['bbox'][1])


NOT_MATH = set('∗*†‡§¶,.;:()[]{} ')


def block_to_md(b, body_size):
    """Returns (markdown, info). info: code (monospace block), math (display formula block), inline_math
    (prose with some math symbols: sub/superscripts may be flattened, e.g. d_k printed as dk)."""
    if b['lines'] and abs(b['lines'][0].get('dir', (1, 0))[0]) < 0.9:
        # Rotated text (margin stamps like the arXiv id, rotated table headers): keep it, but out of the body.
        rot = ' '.join(sp['text'].strip() for ln in b['lines'] for sp in ln['spans'] if sp['text'].strip())
        return (f'<!-- rotated text: {rot} -->' if rot else ''), {'code': False, 'math': False, 'inline_math': False}
    raw_lines, sup_lines, line_sizes = [], [], []
    n_chars = n_mono = n_math = 0
    for ln in b['lines']:
        raw, sup = [], []
        lsize = 0
        for sp in ln['spans']:
            t = sp['text']
            if not t:
                continue
            font = sp.get('font', '')
            vis = len(t.strip())
            if vis:
                n_chars += vis
                lsize = max(lsize, sp['size'])
                if sp['flags'] & 8 or MONO_FONT_RE.search(font):
                    n_mono += vis
                math_font = bool(MATH_FONT_RE.search(font))
                n_math += sum(1 for ch in t if ch in MATH_CHARS or (math_font and not ch.isspace() and ch not in NOT_MATH))
            raw.append(t)
            sup.append(f'<sup>{t.strip()}</sup>' if sp['flags'] & 1 and vis and vis <= 4 else t)
        raw_lines.append(''.join(raw).rstrip())
        sup_lines.append(''.join(sup).rstrip())
        line_sizes.append(lsize)
    ratio = n_math / n_chars if n_chars else 0
    info = {'code': n_chars > 0 and n_mono / n_chars >= 0.8}
    joined_len = sum(len(s) for s in raw_lines)
    info['math'] = not info['code'] and (ratio >= 0.4 or (ratio >= 0.15 and joined_len < 80))
    info['inline_math'] = not info['code'] and not info['math'] and n_math > 0
    if info['code'] or info['math']:
        return '\n'.join(raw_lines), info
    # Leading lines in a bigger font are a heading that PyMuPDF put in the same block as the paragraph.
    heading, start = [], 0
    while start < len(sup_lines) and line_sizes[start] >= body_size * 1.25 and len(' '.join(heading)) < 150:
        if sup_lines[start].strip():
            heading.append(sup_lines[start].strip())
        start += 1
    if start == len(sup_lines) and len(' '.join(heading)) >= 150:
        heading, start = [], 0  # a whole block of big text is not a heading
    text = join_prose(sup_lines[start:])
    if heading:
        level = '##' if max(line_sizes[:start]) >= body_size * 1.6 else '###'
        text = f"{level} {join_prose(heading)}" + (f'\n\n{text}' if text else '')
    return text, info


def join_prose(lines):
    """Join PDF lines into a paragraph. Line-end hyphens: a soft hyphen is dropped; 'rata-' + 'rata' (Indonesian
    reduplication), a capital/digit after the hyphen, or a compound with more hyphens keeps the hyphen; otherwise it
    is a word break and is removed."""
    text = ''
    for ln in lines:
        s = ln.strip()
        if not s:
            continue
        if not text:
            text = s
        elif BULLET_RE.match(s):
            text += '\n' + s
        elif text.endswith('­'):
            text = text[:-1] + s
        elif text.endswith('-') and not text.endswith(' -') and len(text) > 1 and text[-2].isalpha():
            prev = re.split(r'[\s(]', text[:-1])[-1]
            nxt = re.match(r'[\w]+', s)
            nxt = nxt.group(0) if nxt else ''
            compound = '-' in prev or s[len(nxt):len(nxt) + 1] == '-'  # state-of- + the-art, English- + to-German
            if nxt and (nxt.lower() == prev.lower() or nxt[0].isupper() or nxt[0].isdigit() or compound):
                text += s
            else:
                text = text[:-1] + s
        else:
            text = f'{text} {s}'
    return text.replace('­', '')


def save_pdf_image(doc, xref, folder, iid):
    import pymupdf
    folder.mkdir(exist_ok=True)
    try:
        img = doc.extract_image(xref)
        if img and img.get('ext') in ('png', 'jpg', 'jpeg'):
            fname = f"{iid}.{img['ext']}"
            (folder / fname).write_bytes(img['image'])
            return fname
        pix = pymupdf.Pixmap(doc, xref)
        if pix.n - pix.alpha >= 4:
            pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
        fname = f'{iid}.png'
        pix.save(str(folder / fname))
        return fname
    except Exception:
        return None


def run_docling(path, out, ocr, pages):
    """Optional second reading with Docling: formulas as LaTeX, better layout, OCR for scans.
    Only the given pages (1-based) are converted, one by one, so docling.md has the same <!-- page N --> markers as
    text.md. Docling is slow on a CPU (about 1 minute per display formula), so never feed it a whole book."""
    try:
        from docling.datamodel.base_models import InputFormat
        from docling.datamodel.pipeline_options import PdfPipelineOptions
        from docling.document_converter import DocumentConverter, PdfFormatOption
    except ImportError:
        return 'not installed'
    try:
        opts = PdfPipelineOptions()
        opts.do_formula_enrichment = True
        opts.do_table_structure = True
        opts.do_ocr = bool(ocr)
        conv = DocumentConverter(format_options={InputFormat.PDF: PdfFormatOption(pipeline_options=opts)})
        parts = []
        for i, pno in enumerate(pages, 1):
            print(f'  docling: page {pno} ({i}/{len(pages)})', flush=True)
            res = conv.convert(str(path), page_range=(pno, pno))
            parts.append(f'<!-- page {pno} -->\n\n' + res.document.export_to_markdown().strip() + '\n')
        head = f'<!-- Docling reading of pages {compact_pages(pages)} only (pages with formulas or scans). Formulas are LaTeX. -->\n\n'
        (out / 'docling.md').write_text(head + '\n'.join(parts), encoding='utf-8')
        return f'ok (pages {compact_pages(pages)})'
    except Exception as e:
        return f'failed: {type(e).__name__}: {e}'


def compact_pages(pages):
    """[1, 2, 3, 7] -> '1-3, 7'"""
    out, start = [], None
    for i, p in enumerate(pages):
        if start is None:
            start = p
        if i + 1 == len(pages) or pages[i + 1] != p + 1:
            out.append(str(start) if start == p else f'{start}-{p}')
            start = None
    return ', '.join(out)


# ---------------------------------------------------------------------------------------------------------- DOCX

def find_pandoc():
    cands = ['pandoc']
    local = os.environ.get('LOCALAPPDATA')
    if local:
        cands.append(str(Path(local) / 'Pandoc' / 'pandoc.exe'))
    for c in cands:
        if shutil.which(c) or Path(c).exists():
            return shutil.which(c) or c
    return None


def read_docx(path, out, args):
    pandoc = find_pandoc()
    if not pandoc:
        sys.exit('read-doc: pandoc is needed for DOCX. Install it (see tools-check.mjs), then run again.')
    media = out / 'images'
    r = subprocess.run([pandoc, str(path), '-t', 'markdown-smart-simple_tables-multiline_tables-grid_tables', '--wrap=none', '--track-changes=all',
                        f'--extract-media={media}'], capture_output=True, text=True, encoding='utf-8')
    if r.returncode != 0:
        sys.exit(f'read-doc: pandoc failed:\n{r.stderr}')
    text = r.stdout.replace(str(media).replace('\\', '/'), 'images').replace(str(media), 'images')
    # Pandoc puts media in images/media/...; keep paths relative to the output folder.
    text = re.sub(r'\]\((?:[^)]*?)(images[\\/]media[\\/][^)]+)\)', lambda m: '](' + m.group(1).replace('\\', '/') + ')', text)

    counts = Counter()
    counts['formulas'] = len(re.findall(r'(?<!\\)\$[^$\n]+\$', text))
    counts['images'] = len(re.findall(r'!\[', text))
    counts['tables'] = len(re.findall(r'^\s*[+|][-=+|: ]{3,}$', text, re.M)) and text.count('\n+--') + text.count('\n|--')
    counts['tracked_insertions'] = text.count('{.insertion')
    counts['tracked_deletions'] = text.count('{.deletion')
    counts['comments'] = text.count('{.comment-start')

    meta = {}
    try:
        import docx
        d = docx.Document(str(path))
        cp = d.core_properties
        for k in ('title', 'author', 'subject', 'keywords', 'last_modified_by'):
            v = getattr(cp, k, None)
            if v:
                meta[k] = v
        for k in ('created', 'modified'):
            v = getattr(cp, k, None)
            if v:
                meta[k] = v.isoformat()
        counts['tables'] = len(d.tables)
        for i, t in enumerate(d.tables, 1):
            rows = [[c.text for c in row.cells] for row in t.rows]
            (out / 'tables').mkdir(exist_ok=True)
            (out / 'tables' / f't{i}.md').write_text(rows_to_md(rows) + '\n', encoding='utf-8')
    except ImportError:
        meta['note'] = 'python-docx not installed: no metadata or separate table files'

    flags = {}
    notes = []
    if counts['formulas']:
        notes.append(f"{counts['formulas']} equation(s) converted from Word (OMML) to $LaTeX$ - check against the page PNGs")
    if counts['images']:
        notes.append(f"{counts['images']} picture(s) in images/: charts/diagrams pasted as pictures have NO text - look at them")
    if counts['tracked_insertions'] or counts['tracked_deletions']:
        notes.append('tracked changes present: [text]{.insertion} is new, [text]{.deletion} was removed - the final text is without deletions')
    if counts['comments']:
        notes.append("reviewer comments present ({.comment-start ...}) - they are not part of the author's text")
    if notes:
        flags['document'] = notes
    if args.render != 'none' and (counts['formulas'] or counts['images'] or args.render == 'all'):
        rendered = office_render(path, out, args.dpi)
        if rendered:
            flags.setdefault('document', []).append(f'page renders: pages/p001.png .. p{rendered:03d}.png (made by {office_engine()})')
    dois = find_dois(text[:20000])
    result = {'source': str(path), 'type': 'docx', 'metadata': meta, 'doi_candidates': dois, 'counts': dict(counts)}
    header = f'<!-- source: {path.name} | engine pandoc (markdown, tracked changes kept) -->\n\n'
    index = [('all', len(text), flags.get('document', []))]
    return header + text, index, flags, result, counts


# ---------------------------------------------------------------------------------------------------------- PPTX

def read_pptx(path, out, args):
    try:
        from pptx import Presentation
        from pptx.util import Emu  # noqa: F401  (import check)
    except ImportError:
        sys.exit('read-doc: python-pptx is not installed. Run: python -m pip install --user python-pptx')
    from pptx.enum.shapes import MSO_SHAPE_TYPE

    prs = Presentation(str(path))
    md = [f'<!-- source: {path.name} | slides {len(prs.slides)} | engine python-pptx -->']
    index, flags, counts = [], {}, Counter()
    picture_slides, visible = [], []

    for sno, slide in enumerate(prs.slides, 1):
        sflags = []
        hidden = slide._element.get('show') == '0'
        if not hidden:
            visible.append(sno)
        md.append(f'\n<!-- slide {sno}{" (HIDDEN in the show)" if hidden else ""} -->\n')
        title = slide.shapes.title.text_frame.text.strip() if slide.shapes.title is not None and slide.shapes.title.has_text_frame else ''
        if title:
            md.append(f'## {title}\n')
        chars = len(title)

        def walk(shapes, depth=0):
            nonlocal chars
            for sh in sorted(shapes, key=lambda s: ((s.top or 0), (s.left or 0))):
                if slide.shapes.title is not None and sh.shape_id == slide.shapes.title.shape_id:
                    continue
                st = sh.shape_type
                if st == MSO_SHAPE_TYPE.GROUP:
                    walk(sh.shapes, depth + 1)
                elif getattr(sh, 'has_table', False) and sh.has_table:
                    rows = [[c.text for c in row.cells] for row in sh.table.rows]
                    tid = f's{sno}-t{counts["tables"] + 1}'
                    counts['tables'] += 1
                    tmd = rows_to_md(rows)
                    (out / 'tables').mkdir(exist_ok=True)
                    (out / 'tables' / f'{tid}.md').write_text(tmd + '\n', encoding='utf-8')
                    md.append(f'<!-- table {tid} -->\n{tmd}\n')
                    chars += len(tmd)
                elif getattr(sh, 'has_chart', False) and sh.has_chart:
                    counts['charts'] += 1
                    md.append(chart_to_md(sh.chart, sno))
                    sflags.append('chart: numbers above come from the chart data; check the rendered slide for what is shown')
                elif st == MSO_SHAPE_TYPE.PICTURE:
                    counts['images'] += 1
                    (out / 'images').mkdir(exist_ok=True)
                    img = sh.image
                    fname = f's{sno}-img{counts["images"]}.{img.ext}'
                    (out / 'images' / fname).write_bytes(img.blob)
                    alt = sh._element.xpath('./p:nvPicPr/p:cNvPr/@descr')
                    md.append(f'![{alt[0] if alt else "picture"}](images/{fname})\n')
                    sflags.append('picture: describe only what is visible; text inside pictures is NOT in text.md')
                elif sh.has_text_frame and sh.text_frame.text.strip():
                    for p in sh.text_frame.paragraphs:
                        t = ''.join(r.text for r in p.runs).strip()
                        if t:
                            md.append(('  ' * p.level) + ('- ' if p.level or len(sh.text_frame.paragraphs) > 1 else '') + t)
                            chars += len(t)
                    md.append('')
                elif st == MSO_SHAPE_TYPE.EMBEDDED_OLE_OBJECT or 'dgm' in sh._element.xml[:2000]:
                    sflags.append('SmartArt/embedded object: its text may be missing here - read the rendered slide')

        walk(slide.shapes)
        if slide.has_notes_slide:
            notes = slide.notes_slide.notes_text_frame.text.strip() if slide.notes_slide.notes_text_frame else ''
            if notes:
                md.append(f'> Catatan pembicara (speaker notes): {notes}\n')
                chars += len(notes)
        if hidden:
            sflags.append('hidden slide: not shown in the presentation, mention that if you use it')
        if sflags:
            flags[sno] = sorted(set(sflags))
            picture_slides.append(sno)
        index.append((sno, chars, flags.get(sno, [])))

    if args.render != 'none' and (picture_slides or args.render == 'all'):
        rendered = office_render(path, out, args.dpi)
        if rendered and rendered == len(visible) < len(prs.slides):
            # Office skips hidden slides when exporting: rename so pNNN.png is always slide NNN.
            for i in range(rendered, 0, -1):
                (out / 'pages' / f'p{i:03d}.png').rename(out / 'pages' / f'p{visible[i - 1]:03d}.png')
        if rendered:
            note = ' (hidden slides have no render)' if len(visible) < len(prs.slides) else ''
            flags.setdefault('document', []).append(f'slide renders: pages/pNNN.png = slide NNN, made by {office_engine()}{note}')
    cp = prs.core_properties
    meta = {k: getattr(cp, k) for k in ('title', 'author', 'subject') if getattr(cp, k, None)}
    result = {'source': str(path), 'type': 'pptx', 'slides': len(prs.slides), 'metadata': meta, 'counts': dict(counts)}
    return '\n'.join(md), index, flags, result, counts


def chart_to_md(chart, sno):
    try:
        plot = chart.plots[0]
        cats = [str(c) for c in plot.categories]
        rows = [['series'] + cats]
        for s in plot.series:
            rows.append([s.name or ''] + ['' if v is None else f'{v:g}' for v in s.values])
        title = chart.chart_title.text_frame.text if chart.has_title and chart.chart_title.has_text_frame else ''
        return f'<!-- chart on slide {sno}: {chart.chart_type} {title} -->\n' + rows_to_md(rows) + '\n'
    except Exception as e:
        return f'<!-- chart on slide {sno}: data not readable ({type(e).__name__}) - read the rendered slide -->\n'


# ---------------------------------------------------------------------------------------------- Office rendering

def office_engine():
    if sys.platform == 'win32':
        return 'Microsoft Office or LibreOffice'
    return 'LibreOffice'


def office_render(path, out, dpi):
    """DOCX/PPTX -> PDF with Office (Windows COM) or LibreOffice, then PDF pages -> PNG. Returns page count or 0."""
    try:
        import pymupdf
    except ImportError:
        return 0
    tmp = Path(tempfile.mkdtemp(prefix='readdoc-'))
    pdf = tmp / 'render.pdf'
    src = str(path.resolve())
    ok = False
    if sys.platform == 'win32':
        if path.suffix.lower() == '.pptx':
            ps = (f"$a=New-Object -ComObject PowerPoint.Application; try {{ $p=$a.Presentations.Open('{src}',$true,$false,$false); "
                  f"$p.SaveAs('{pdf}',32); $p.Close() }} finally {{ $a.Quit() }}")
        else:
            ps = (f"$a=New-Object -ComObject Word.Application; $a.Visible=$false; try {{ $d=$a.Documents.Open('{src}',$false,$true); "
                  f"$d.SaveAs2('{pdf}',17); $d.Close($false) }} finally {{ $a.Quit() }}")
        r = subprocess.run(['powershell', '-NoProfile', '-Command', ps], capture_output=True, text=True, timeout=300)
        ok = r.returncode == 0 and pdf.exists()
    if not ok:
        soffice = shutil.which('soffice') or shutil.which('libreoffice')
        for c in [r'C:\Program Files\LibreOffice\program\soffice.exe', '/Applications/LibreOffice.app/Contents/MacOS/soffice']:
            if not soffice and Path(c).exists():
                soffice = c
        if soffice:
            subprocess.run([soffice, '--headless', '--convert-to', 'pdf', '--outdir', str(tmp), src], capture_output=True, timeout=300)
            alt = tmp / (path.stem + '.pdf')
            if alt.exists():
                alt.rename(pdf)
                ok = True
    if not ok:
        shutil.rmtree(tmp, ignore_errors=True)
        return 0
    doc = pymupdf.open(str(pdf))
    (out / 'pages').mkdir(exist_ok=True)
    for i, page in enumerate(doc, 1):
        page.get_pixmap(dpi=dpi).save(str(out / 'pages' / f'p{i:03d}.png'))
    n = doc.page_count
    doc.close()
    shutil.rmtree(tmp, ignore_errors=True)
    return n


# ------------------------------------------------------------------------------------------------------- report

def write_report(out, path, kind, index, flags, result, counts, docling_status):
    unit = 'slide' if kind == 'pptx' else 'page'
    L = [f'# Reading report: {path.name}', '',
         f'Made by read-doc.py on {datetime.now():%Y-%m-%d %H:%M}. Type: {kind}. Engine: {"pymupdf" if kind == "pdf" else "pandoc" if kind == "docx" else "python-pptx"}.',
         '']
    if result.get('doi_candidates'):
        L.append(f"DOI found in the document: {', '.join(result['doi_candidates'][:3])} (the first one is usually the paper's own DOI; confirm on the first page).")
        L.append('')
    c = ', '.join(f'{k}: {v}' for k, v in counts.items() if v) or 'none'
    L += [f'Counts: {c}.', '']
    L += ['## What you must do before citing this document', '',
          '1. Read text.md in chunks (a few pages at a time) and write the note card as you go. Do not read it all and summarize from memory.',
          f'2. Every {unit} listed under "Flagged" below has content the text layer cannot carry exactly. Open the PNG named there.',
          '   No vision (cannot see images)? Do not guess: write "belum diverifikasi (perlu model yang bisa membaca gambar)" in the note card,',
          '   or use docling.md if it exists, or ask the user to switch to a vision model for this step (.agents/knowledge/reading.md).',
          '3. Numbers, quotes and formulas you will cite: copy them exactly with the page number, and check them against the PNG.',
          '']
    if docling_status:
        L += [f'Docling: {docling_status}' + (' -> docling.md (formulas as LaTeX). Compare with text.md; when they disagree, the page PNG decides.' if docling_status.startswith('ok') else ''), '']
    L += ['## Flagged', '']
    if flags:
        for k, fl in flags.items():
            label = k if isinstance(k, str) else f'{unit} {k}'
            L.append(f'- **{label}**')
            L += [f'  - {f}' for f in fl]
    else:
        L.append('- nothing flagged: the text layer looks complete. Still spot-check one page PNG if you render it.')
    L += ['', f'## {unit.capitalize()} index', '', f'| {unit} | chars | flags |', '|---|---|---|']
    for n, chars, fl in index:
        L.append(f'| {n} | {chars} | {len(fl)} |')
    (out / 'report.md').write_text('\n'.join(L) + '\n', encoding='utf-8')


def probe_pdf(path):
    try:
        import pymupdf
    except ImportError:
        print('read-doc: pymupdf is not installed (python -m pip install --user pymupdf)', file=sys.stderr)
        return 2
    try:
        doc = pymupdf.open(str(path))
    except Exception as e:  # not a PDF, or damaged
        print(json.dumps({'error': f'cannot open as PDF: {e}'}))
        return 1
    first = doc[0].get_text() if doc.page_count else ''
    second = doc[1].get_text() if doc.page_count > 1 else ''
    meta = doc.metadata or {}
    arxiv = re.search(r'arXiv:\s*(\d{4}\.\d{4,5})(v\d+)?', first + second)
    print(json.dumps({'dois': find_dois(f"{meta.get('subject', '')} {meta.get('keywords', '')} {first} {second}"),
                      'arxiv': arxiv.group(1) if arxiv else None,
                      'title': meta.get('title') or '', 'pages': doc.page_count, 'first_page': first[:3000]},
                     ensure_ascii=False))
    return 0


def main():
    ap = argparse.ArgumentParser(description='Read a PDF/DOCX/PPTX precisely (see the file header).')
    ap.add_argument('file')
    ap.add_argument('--out')
    ap.add_argument('--key')
    ap.add_argument('--pages')
    ap.add_argument('--render', choices=['flagged', 'all', 'none'], default='flagged')
    ap.add_argument('--dpi', type=int, default=110)
    ap.add_argument('--engine', choices=['auto', 'pymupdf', 'docling'], default='auto')
    ap.add_argument('--probe', action='store_true')
    args = ap.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f'read-doc: file not found: {path}', file=sys.stderr)
        return 2
    if args.probe:
        return probe_pdf(path)
    kind = path.suffix.lower().lstrip('.')
    if kind not in ('pdf', 'docx', 'pptx'):
        print('read-doc: only .pdf, .docx and .pptx (convert .doc/.ppt with Office or LibreOffice first)', file=sys.stderr)
        return 2
    key = args.key or slug(path.stem)
    out = Path(args.out) if args.out else Path('research') / 'text' / key
    if out.exists():
        for sub in ('pages', 'images', 'tables'):
            shutil.rmtree(out / sub, ignore_errors=True)
    out.mkdir(parents=True, exist_ok=True)

    reader = {'pdf': read_pdf, 'docx': read_docx, 'pptx': read_pptx}[kind]
    text, index, flags, result, counts = reader(path, out, args)

    docling_status = None
    if kind == 'pdf' and args.engine != 'pymupdf':
        hard = counts.get('formulas') or any('scanned' in f for fl in flags.values() for f in fl)
        import importlib.util
        if not importlib.util.find_spec('docling'):
            if args.engine == 'docling' or hard:
                docling_status = 'not installed - formulas only as page crops (pip install --user docling, in the background)'
        elif args.engine == 'docling' or hard:
            scanned = any('scanned' in f for fl in flags.values() for f in fl)
            hard_pages = sorted(p for p, fl in flags.items() if isinstance(p, int)
                                and any('formula block' in f or 'scanned' in f for f in fl))
            if args.engine == 'docling' and (args.pages or not hard_pages):
                hard_pages = [i + 1 for i in parse_pages(args.pages, result['pages_total'])]
            print(f'read-doc: running Docling on {len(hard_pages)} page(s) with formulas/scans: {compact_pages(hard_pages)}. '
                  'Slow on a CPU (about 1 minute per formula; the first run also downloads ~1 GB of models)...', flush=True)
            docling_status = run_docling(path, out, scanned, hard_pages)
    result['docling'] = docling_status
    result['key'] = key
    # Runs of rotated words (labels inside figures) become one comment.
    rot_run = re.compile(r'<!-- rotated text: ([^>]*?) -->\s*<!-- rotated text: ([^>]*?) -->')
    while rot_run.search(text):
        text = rot_run.sub(r'<!-- rotated text: \1 \2 -->', text)
    (out / 'text.md').write_text(text + '\n', encoding='utf-8')
    (out / 'meta.json').write_text(json.dumps(result, ensure_ascii=False, indent=2, default=str), encoding='utf-8')
    write_report(out, path, kind, index, flags, result, counts, docling_status)

    nflag = sum(1 for k in flags)
    print(f'read-doc: {path.name} -> {out}')
    print(f"  text.md ({len(text)} chars), report.md, meta.json; flagged: {nflag}; " + ', '.join(f'{k} {v}' for k, v in counts.items() if v))
    if result.get('doi_candidates'):
        print(f"  DOI: {result['doi_candidates'][0]}")
    if docling_status:
        print(f'  docling: {docling_status}')
    print('  Next: read report.md first, then text.md page by page (.agents/knowledge/reading.md).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
