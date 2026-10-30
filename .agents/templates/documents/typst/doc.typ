// Workflow Kit - Typst template for Pandoc (Markdown -> PDF).
// Used by .agents/scripts/doc-build.mjs via `-V template=...`. Do not edit per document:
// change the look through front matter (fontsize, linestretch, margin, mainfont, ...) or a new preset.
// Presets: "laporan" (default, reports/proposals/notes) and "akademik" (makalah/skripsi-style).

#let content-to-string(content) = {
  if content == none { return "" }
  if type(content) == str { return content }
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  } else { "" }
}

#let presets = (
  laporan: (
    paper: "a4",
    margin: (x: 2.5cm, y: 2.5cm),
    font: ("Cambria", "Libertinus Serif"),
    fontsize: 11pt,
    linestretch: 1.2,
    indent: 0pt,
    par-gap: 0.85em,
    title-align: left,
    h1-align: left,
  ),
  akademik: (
    paper: "a4",
    margin: (left: 4cm, top: 4cm, right: 3cm, bottom: 3cm),
    font: ("Times New Roman", "Libertinus Serif"),
    fontsize: 12pt,
    linestretch: 1.5,
    indent: 1.25cm,
    par-gap: none,
    title-align: center,
    h1-align: center,
  ),
)

#let pick(value, fallback) = if value == auto or value == none { fallback } else { value }

#let conf(
  preset: "laporan",
  title: none,
  subtitle: none,
  authors: (),
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  margin: auto,
  paper: auto,
  lang: "id",
  region: "ID",
  font: auto,
  fontsize: auto,
  mathfont: none,
  codefont: none,
  linestretch: auto,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  pagenumbering: "1",
  doc,
) = {
  let p = presets.at(preset)
  let fontsize = pick(fontsize, p.fontsize)
  let linestretch = pick(linestretch, p.linestretch)
  let fonts = if font == auto or font == none { p.font } else { font + p.font }
  // Line spacing close to Word: line box = ascender..descender, extra gap grows with linestretch.
  let leading = (linestretch - 1) * 1.15em + 0.06em
  let ink = rgb("#1b1b1b")
  let muted = rgb("#5a5a5a")
  let rule = rgb("#9a9a9a")
  let link-ink = if linkcolor != none { rgb(content-to-string(linkcolor)) } else { rgb("#1f4e8c") }

  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(a => content-to-string(a.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()

  set page(
    paper: pick(paper, p.paper),
    margin: pick(margin, p.margin),
    columns: cols,
    numbering: pick(pagenumbering, "1"),
    number-align: center + bottom,
    footer-descent: 40%,
  )

  set text(
    lang: lang, region: region, font: fonts, size: fontsize, fill: ink,
    top-edge: "ascender", bottom-edge: "descender", hyphenate: false,
  )
  set par(
    justify: true,
    leading: leading,
    spacing: pick(p.par-gap, leading),
    first-line-indent: (amount: p.indent, all: true),
    justification-limits: (tracking: (min: -0.01em, max: 0.02em)),
  )
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: if codefont != none { codefont } else { ("DejaVu Sans Mono", "Consolas") }, size: 0.88em)

  // Headings: hierarchy from size and weight only. No color, no rules, no numbering unless asked.
  set heading(numbering: sectionnumbering)
  show heading: set text(weight: "bold", hyphenate: false)
  show heading: set par(justify: false, first-line-indent: 0pt)
  // Absolute sizes: relative `em` would compound with Typst's built-in heading sizes.
  show heading.where(level: 1): set text(size: fontsize * 1.3)
  show heading.where(level: 1): set align(p.h1-align)
  show heading.where(level: 1): set block(above: 1.9em, below: 0.85em)
  show heading.where(level: 2): set text(size: fontsize * 1.13)
  show heading.where(level: 2): set block(above: 1.6em, below: 0.75em)
  show heading.where(level: 3): set text(size: fontsize)
  show heading.where(level: 3): set block(above: 1.4em, below: 0.65em)
  show heading.where(level: 4): set text(size: fontsize, weight: "regular", style: "italic")

  // Lists: compact, aligned with the text.
  set list(indent: 0.4em, body-indent: 0.6em, marker: ([•], [–]))
  set enum(indent: 0.4em, body-indent: 0.6em)
  set terms(hanging-indent: 1.5em)
  show list: set par(justify: false, first-line-indent: 0pt)
  show enum: set par(justify: false, first-line-indent: 0pt)

  // Tables: booktabs style (top, header, bottom rules; no vertical lines; no fills).
  set table(
    inset: (x: 6pt, y: 4.5pt),
    stroke: (x, y) => if y == 0 { (top: 0.9pt + ink, bottom: 0.5pt + ink) },
  )
  show table: it => block(stroke: (bottom: 0.9pt + ink), it)
  show table: set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  show table: set text(size: 0.92em)
  show table.cell.where(y: 0): set text(weight: "bold")

  // Figures and captions: "Gambar 1. ..." / "Tabel 1. ..." (localized by lang).
  set figure(gap: 0.7em)
  set figure.caption(separator: [. ])
  show figure.caption: set text(size: 0.92em)
  show figure.caption: set par(justify: false, first-line-indent: 0pt)
  show figure: set block(above: 1.4em, below: 1.4em)
  show figure.where(kind: table): set figure.caption(position: top)

  // Code, quotes, links.
  show raw.where(block: true): block.with(fill: luma(246), inset: 9pt, radius: 2pt, width: 100%)
  show raw.where(block: true): set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  show quote.where(block: true): it => pad(left: 1.2em, block(
    stroke: (left: 1.5pt + rule), inset: (left: 0.9em, y: 0.2em),
    text(fill: muted, it.body),
  ))
  show link: set text(fill: link-ink)
  show ref: set text(fill: link-ink) if citecolor != none
  show footnote.entry: set text(size: 0.85em)
  show footnote.entry: set par(first-line-indent: 0pt)
  // Reference list made by --citeproc (Pandoc labels it <refs>): hanging indent, ragged right.
  show <refs>: set par(first-line-indent: 0pt, hanging-indent: 1.25cm, justify: false)

  // Table of contents.
  show outline.entry.where(level: 1): set text(weight: "bold")
  set outline(indent: auto)

  // Title block.
  if title != none {
    block(width: 100%, below: 1.6em, {
      set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
      set align(p.title-align)
      text(size: 1.75em, weight: "bold", hyphenate: false, title)
      if thanks != none { footnote(thanks, numbering: "*"); counter(footnote).update(n => n - 1) }
      if subtitle != none {
        v(0.35em)
        text(size: 1.15em, fill: muted, subtitle)
      }
      let names = if authors != none and authors != () {
        authors.map(a => {
          let parts = (a.name,)
          if a.affiliation != "" and a.affiliation != [] { parts.push(a.affiliation) }
          parts.join(", ")
        })
      } else { () }
      let meta = names + if date != none { (date,) } else { () }
      if meta.len() > 0 {
        v(0.7em)
        text(fill: muted, meta.join([ #h(0.4em)·#h(0.4em) ]))
      }
      if p.title-align == left { v(0.6em); line(length: 100%, stroke: 0.5pt + rule) }
    })
  }
  if abstract != none {
    block(width: 100%, inset: (x: 1.5em), below: 1.6em, {
      set par(first-line-indent: 0pt)
      set text(size: 0.95em)
      text(weight: "bold", if abstract-title != none { abstract-title } else { [Abstrak] })
      linebreak()
      abstract
    })
  }
  doc
}
