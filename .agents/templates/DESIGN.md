# Design system — <Product name>

> How the product looks, feels, and talks. Every UI change follows this file.
> Anti-slop rules: `.agents/knowledge/ui-ux.md` and `.agents/knowledge/copywriting.md` always apply.

## 1. Personality
- **Three words:** <e.g. calm, precise, trustworthy>
- **Reference products** (quality bar, not to copy): <e.g. Linear, Stripe Dashboard, GitHub>
- **Not:** <e.g. playful, flashy, futuristic>

## 2. Color
Neutral-first. One accent, used sparingly (primary buttons, links, focus, active state). Light theme is the default.
| Token | Value | Use |
|---|---|---|
| `bg` | | page background |
| `surface` | | panels, inputs, popovers |
| `border` | | 1px neutral borders, dividers |
| `text` | | body text |
| `text-muted` | | secondary text (still ≥ 4.5:1 contrast) |
| `accent` | | primary actions, links, focus ring |
| `accent-fg` | | text on accent |
| `success` / `warning` / `danger` | | status only, never decoration |

Dark mode: <not supported | supported via tokens (same hierarchy, not a "neon" variant)>

## 3. Typography
| Role | Font / size / weight / line-height |
|---|---|
| Font family | <one sans-serif; optional mono for numbers/code> |
| Page title | |
| Section title | |
| Body | <≥ 16px web, ≥ 14sp mobile> |
| Small / caption | |

Numbers in tables use tabular figures.

## 4. Spacing, radius, elevation
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64 (px). Nothing off-scale.
- Radius: <e.g. 6px controls, 8px panels>. One or two values only.
- Shadows: <e.g. none on panels; small shadow only on popovers/menus/modals>.

## 5. Layout
- Max content width: <e.g. 1200px app, 720px reading>
- Grid / breakpoints: <e.g. 640 / 768 / 1024 / 1280>
- Navigation pattern: <e.g. left sidebar on desktop, bottom nav on mobile>
- Data views: tables for records, lists for feeds, cards only for truly separate objects with mixed content.

## 6. Components
Built on: <e.g. shadcn/ui, Material 3, project's own>. Document only variants we actually use.
| Component | Variants in use | Notes |
|---|---|---|
| Button | primary, secondary, ghost, destructive | one primary per view |
| Input / Select | default, error, disabled | label always visible |
| Table | default, compact | sticky header for long tables |
| Dialog | default, confirm-destructive | |
| Toast | success, error | short, no emoji |

## 7. Icons & imagery
- Icon set: <one set, e.g. Lucide>, single stroke width, sized to text. Icons support labels, they don't replace them.
- Images: real screenshots/photos or none. No stock "AI" illustrations, blobs, or 3D shapes.

## 8. Motion
- Duration 150–200ms, ease-out. Only for state changes (open/close, hover, feedback). No decorative animation.
- Respect `prefers-reduced-motion`.

## 9. Voice & copy
- Address the user as: <Anda | kamu> — consistently.
- Tone: <e.g. direct, polite, plain>
- Case: sentence case for titles and buttons.

**Glossary** (always use these exact terms):
| Use | Don't use |
|---|---|
| <e.g. Produk> | <Barang, Item, Artikel> |
