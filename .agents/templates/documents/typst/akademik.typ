// Preset "akademik": Times New Roman 12pt, spacing 1.5, margins 4-4-3-3, first-line indent, centered H1.
// Typical Indonesian campus rules. If the user's guideline (pedoman) says otherwise, override in front matter.
#import "doc.typ": conf as base
#let conf(..args) = base(preset: "akademik", ..args)
