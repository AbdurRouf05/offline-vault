// Preset "laporan" (default): reports, proposals, SOPs, notes. Cambria 11pt, spacing ~1.2, margins 2.5 cm.
#import "doc.typ": conf as base
#let conf(..args) = base(preset: "laporan", ..args)
