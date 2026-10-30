# UI / UX Quality & Anti-Slop Rules

AI slop looks fine at a glance but fails when a real person uses it. Judge UI by use, not by screenshot.

Good UI is restrained: clear hierarchy from typography and spacing, neutral colors, one accent, real content, every state handled.
"AI slop" is the opposite: decoration added to hide a lack of structure. The project's `docs/DESIGN.md` overrides
defaults here, but the banned list applies unless DESIGN.md explicitly allows an item.

## Banned patterns (AI slop) — never use these by default

| Banned | Do instead |
|---|---|
| Cards with a thick colored border on one side (`border-l-4 border-blue-500`, `border-left: 4px solid`) | Full 1px neutral border, or no border and spacing; status shown with text/icon |
| Gradients: backgrounds, buttons, text (`bg-gradient-to-*`, `bg-linear-*`, `linear-gradient`, `bg-clip-text`) | Solid colors from the tokens |
| Purple/indigo/violet as the "default" brand color | The accent defined in DESIGN.md; if none, ask or pick a calm neutral-friendly accent |
| Dark theme as the default, "space/galaxy/cyber" themes, neon glow, starfields, aurora blobs | Light theme default; dark mode only as a token-based variant if requested |
| Glassmorphism (`backdrop-blur` panels), floating blurred blobs, noise textures, 3D shapes | Plain surfaces |
| Emoji as icons or in headings, buttons, labels, toasts, empty states (🚀 ✨ 🎉 ✅ 💡) | One icon set (e.g. Lucide) used sparingly, or text only |
| Decorative badges/pills ("New", "Pro", "AI-powered", "Beta", "🔥 Hot") on cards and headers | Badges only for real data status (e.g. order status "Paid"), and sparingly |
| Everything inside cards; 3-column "feature cards" with icon + title + 2 lines | Typography, spacing, dividers, lists, tables. Cards only for truly separate objects |
| Hero with a giant gradient headline, "Unlock / Supercharge / Revolutionize…" | Plain headline that says what the product does (see `copywriting.md`) |
| Fake stats, fake testimonials, fake logos ("10k+ happy users") | Real data or nothing |
| Huge radius + heavy shadow on everything (`rounded-3xl shadow-2xl`) | 1–2 small radius values; shadow only on overlays (menus, dialogs) |
| Center-aligned everything in app screens | Left-aligned text and forms; center only short marketing hero/empty states |
| Animations everywhere: hover lifts, bouncing, pulsing, parallax, typewriter text | 150–200ms state transitions only |
| Many accent colors per screen, colored section backgrounds | Neutral page + one accent for primary actions |
| Lorem ipsum, "John Doe", placeholder images in finished work | Realistic sample data in the user's language and locale |
| Radial glow / light circles behind content, neon purple-pink-cyan accents | Nothing behind content; contrast comes from type and spacing |
| Decorative "futuristic" details: thin grid lines, coordinate dots, scan lines, sci-fi frames | Remove. Every element must have a job |
| CTA overload: several loud buttons competing on one screen | One primary action per view; others secondary/ghost or in a menu |
| Mixed icon styles (outline + solid, different stroke widths, different sets) | One icon set, one style, one stroke width |
| Font sizes/weights jumping without a scale | Only the sizes defined in DESIGN.md typography table |
| Inconsistent padding/margins (cramped here, empty there) | Only values from the spacing scale; same component = same spacing |
| Redundant / overlapping elements (duplicate actions, a button for something already on screen) | Each action appears once, where the user expects it |
| Looks good only as a static mockup; breaks on mobile or with real (long) data | Test with real-length data and at 375px before calling it done |

Mechanical check: `.agents/hooks/ui-slop-check.sh` flags the most common patterns. If a pattern is truly needed,
add `slop-ok: <reason>` in a comment on the same line — and it must be justified by DESIGN.md.

## Foundations

- **Use the project's component library** (web: Tailwind + shadcn/ui unless the project has another; Flutter: Material 3
  with a custom theme). Don't hand-style what the library provides.
- **Tokens only**: colors, spacing, radius, font sizes come from DESIGN.md / theme. No random hex values or pixel numbers.
- **Hierarchy through type and space**, not color and boxes: size, weight, muted text color, whitespace.
- **Spacing scale** 4/8-based. Group related things closer than unrelated things.
- **Typography**: one sans-serif family (+ optional mono). Body ≥ 16px web. Sentence case. Tabular numbers in tables.
- **Color**: neutral grays + one accent + semantic status colors. Text contrast ≥ 4.5:1 (WCAG AA).
- **Density fits the job**: dashboards and admin tools are dense (tables, compact rows); marketing pages breathe.

## Every data screen has 4 states

| State | Must show |
|---|---|
| Loading | Skeleton matching the final layout, or a spinner in place; submit buttons disabled while pending |
| Empty | What will appear here + the primary action ("Belum ada produk. Tambah produk") |
| Error | What went wrong in plain language + how to fix / retry. Never raw stack traces |
| Success | The content; after mutations, visible feedback (inline message, toast, updated list) |

## Forms

- Visible label on every field (placeholder is not a label). Mark required or optional consistently.
- Validate inline with specific messages, next to the field; keep the user's input on error.
- Correct input types/keyboards (`email`, `tel`, `inputmode="numeric"`, date pickers).
- Button text = the action ("Simpan perubahan"). One primary button per form. Destructive actions need confirmation
  that names what will be deleted.
- Map server validation errors to the matching fields.

## Layout & responsiveness

- Mobile-first on web. Check ~375px, ~768px, ≥1280px. No horizontal scroll on mobile (tables scroll inside their container).
- Touch targets ≥ 44×44px.
- Long names, long numbers, and translations must not break layout (wrap or truncate with full text available).
- Locale formatting: `Rp 1.250.000`, `11 Okt 2026`, `14.30 WIB` for Indonesian users.

## Accessibility (minimum)

- Semantic elements (`button` for actions, `a` for navigation, headings in order, `label` for inputs).
- Fully keyboard usable, visible focus ring.
- `alt` on meaningful images, `alt=""` on decorative ones; icon-only buttons have an accessible label.
- Never convey meaning by color alone.

## Verify UI changes

1. Run the app and look at the screens you changed (screenshot them if your environment allows — Playwright can:
   `await page.screenshot({ path: 'tmp/screen.png', fullPage: true })`).
2. Check the 4 states, narrow + wide widths, keyboard navigation for forms.
3. Run `sh .agents/hooks/ui-slop-check.sh <changed files>` and go through the banned list above manually.
4. Read every visible string against `copywriting.md`.
