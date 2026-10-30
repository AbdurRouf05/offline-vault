---
name: wf-design
description: Create or update the design system (docs/DESIGN.md), build or restyle UI screens from it, and review UI and copy for AI-slop. Use for anything about look and feel, layout, styling, theming, components, landing pages, or UI text.
---

# wf-design — Restrained, consistent, usable UI

UI made by AI fails in a predictable way: decoration instead of structure (gradients, glow, cards in cards, emoji,
badges, hype copy) and screens that only work as a static mockup. This skill prevents that.
Always read `.agents/knowledge/ui-ux.md` and `.agents/knowledge/copywriting.md` first.

Pick the mode that fits the request.

## Mode A — Create DESIGN.md (new project, or no design system yet)

1. Grill the user (`.agents/knowledge/grill-me.md`: options, recommendation, pros/cons) about:
   - Three words for the personality (default: calm, clear, trustworthy) and what it should NOT feel like.
   - Reference products they like the quality of (default: Linear, Stripe Dashboard).
   - Existing brand color/logo? (no → you propose one calm accent; never purple/indigo by default).
   - Audience language and address: Anda or kamu.
   - Dense tool (dashboard/admin) or spacious (marketing/consumer)?
2. Fill `docs/DESIGN.md` from `.agents/templates/DESIGN.md`:
   - Neutral palette + ONE accent + status colors; check contrast (text ≥ 4.5:1).
   - One font family; a type scale of 4–6 sizes; spacing scale; 1–2 radius values; shadows only for overlays.
   - Components from the project's library (shadcn/ui, Material 3, …) — only variants actually needed.
   - One icon set, one stroke width. Voice rules and a glossary of product terms.
3. Wire tokens into code (Tailwind theme / CSS variables / Flutter `ThemeData`) so components use names, not raw values.

CHECKPOINT: show a short summary (palette, type scale, personality, glossary). Wait for OK.

## Mode B — Build or restyle a screen

1. Read `docs/DESIGN.md`. No DESIGN.md → do Mode A first (or a minimal version, and say so).
2. Before code, write the screen's structure in chat: purpose (one sentence), the ONE primary action, content blocks in
   order of importance, and the 4 states (loading / empty / error / success).
3. Build with existing components and tokens only. Hierarchy from type size, weight, and spacing — not boxes and color.
4. Use realistic data in the user's language: long names, big numbers, zero items, many items.
5. Write the copy with `copywriting.md` (buttons = verb + object, errors say what to do).
6. Verify (next section). Atomic commit per screen or component.

## Mode C — Review / de-slop existing UI

1. Run `sh .agents/hooks/ui-slop-check.sh <files>` (or on all UI files: list them with `git ls-files`).
2. Walk through the banned table in `ui-ux.md` screen by screen. Also check: more than one primary button per view,
   mixed icon styles, off-scale spacing or font sizes, duplicate actions, decorative elements with no job.
3. Read every visible string against `copywriting.md`.
4. Report findings as a table: location | problem | fix. Fix them in small commits, behavior unchanged.

## Verify (all modes)

- [ ] Ran the app and looked at every changed screen (Playwright screenshot if you cannot see it directly).
- [ ] 4 states handled; ~375px, ~768px, ≥1280px; no horizontal scroll; long text does not break layout.
- [ ] Keyboard navigation and visible focus; labels on inputs; icon-only buttons have accessible names.
- [ ] Only DESIGN.md tokens; one primary action per view; one icon style.
- [ ] `ui-slop-check.sh` clean (or each `slop-ok:` justified by DESIGN.md).
- [ ] Copy follows the glossary and `copywriting.md`; no emoji, no hype words.

## Finish
Re-read `AGENTS.md` §5 (Definition of Done). Update `docs/PROGRESS.md` (and DESIGN.md if tokens/components changed).
Report per `AGENTS.md` §6.
