# Grill me — how to ask the user

When something is unclear, **ask, don't guess**. But ask well: few questions, real options, a recommendation, and the
trade-offs, so the user can decide in seconds.

## When to grill

- Requirement or acceptance criteria unclear, or two reasonable readings lead to different code.
- Decisions that are costly to undo: stack, database schema, auth, payments, permissions, deleting data, paid services,
  public API shape, UI direction (no DESIGN.md yet).
- NOT for things you can find in the code, docs, or `--help`. Look first.
- NOT for cheap, reversible details: pick a sensible default and note it as an assumption.

## How to ask

1. **Use the agent's interactive question tool if it has one** (a tool that shows the user clickable options with an
   "Other" field, e.g. `AskUserQuestion` in Claude Code). Not a free-text chat question.
2. **No such tool?** Use the chat format below, then STOP and wait for the answer. Do not continue working.
3. Max **4 questions per round**, most important first. More open points → ask the rest in the next round.
4. Each question has **2–4 options**. Put your recommendation first and mark it `(Rekomendasi)`.
5. Each option says briefly **kelebihan** (pros) and **kekurangan** (cons) — tied to THIS project, not generic.
6. Always allow **Other / Lainnya** (free answer or a question back).
7. Questions in Bahasa Indonesia, plain words. Explain jargon in a few words.

Chat fallback format:
```
Pertanyaan 1/2 — <topik singkat>
<pertanyaan>
  A. <opsi> (Rekomendasi) — Kelebihan: … Kekurangan: …
  B. <opsi> — Kelebihan: … Kekurangan: …
  C. <opsi> — Kelebihan: … Kekurangan: …
  Lainnya: tulis jawaban sendiri, atau tanya balik kalau belum jelas.
Jawab contoh: "1A, 2 lainnya: ..."
```

## When the user answers "Other" / asks back

- If they asked a question or say they don't understand: **explain** in simple terms (what it means, an everyday analogy,
  what changes for them in practice), then **ask the same question again** with the options, your recommendation,
  and pros/cons — refined using what you just learned.
- If they gave a custom answer: confirm how you understood it in one sentence; if it is still ambiguous, grill again.
- Read the answer carefully: it may change the plan, combine options, or say "not now". Follow what it actually says.

## After the answers

- Record decisions where they belong: PRD (scope/behavior), DESIGN (look/copy), DATABASE (schema), ADR (significant).
- Never re-ask something already decided in the docs — read them first. (Exception: the user now asks for something
  DIFFERENT from that decision → that is a Change check, below.)

## Change check (AGENTS.md rule 12) — mandatory

The user asks for something that goes against the plan. Examples: "pakai MongoDB saja" when `docs/PROJECT.md` says
PostgreSQL; "hapus fitur login" when the PRD has it as Must; "pakai warna ungu gradien" when the kit bans it; "ganti
sitasi ke IEEE" after `research/RESEARCH.md` recorded APA 7; "tidak usah test" when the rules require tests; "skip
saja hook-nya". The user may be right (plans change), may have forgotten the earlier decision, or may have said it
casually. You cannot know which, so you ask. You never silently comply and you never silently refuse.

### Step 1: detect

Before acting on any request, ask yourself: "Does this contradict a kit rule, a recorded decision, or something the
user said earlier?" Look in this order (stop at the first hit, but mention all hits you found):

| Source                                  | What counts as a decision                              |
|-----------------------------------------|--------------------------------------------------------|
| `AGENTS.md` §3–§5, `.agents/knowledge/*` | kit rules (tests, security, anti-slop, pnpm, citations) |
| `docs/PROJECT.md`                       | stack, commands, docs language, tools setup             |
| `docs/PRD.md`                           | scope, Must/Should/Won't, acceptance criteria           |
| `docs/DESIGN.md`, `docs/DATABASE.md`    | look, copy, schema                                      |
| `docs/decisions/*.md` (ADR)             | anything decided with reasons                           |
| `docs/IDEA.md`, the current `PLAN`      | direction, chosen options, order of work                |
| `research/RESEARCH.md`                  | research questions, scope, citation style, sources      |
| `docs/HANDOFF.md` → decisions           | decisions made in recent sessions                       |
| `docs/CHATLOG.md`                       | what the user said earlier, in their own words          |

Not a change: filling in a detail the plan left open, or something the plan explicitly allows. Then just proceed.

### Step 2: ask (grill-me tool, or the chat format)

The question MUST contain these three parts, in Bahasa Indonesia, before the options:

```
Perubahan dari rencana — mohon dipastikan
Awalnya : <keputusan lama>  (sumber: <file> → <bagian>, <tanggal kalau ada>)
Alasannya dulu: <kenapa dulu diputuskan begitu, dari ADR/PRD/CHATLOG; "tidak tercatat" kalau memang tidak ada>
Sekarang diminta: <permintaan baru, dengan kata-kata user>
Dampak : <apa yang berubah: file/fitur yang terdampak, kerja ulang, risiko, biaya; jujur dan konkret>
```

Then the options (recommendation first, pros/cons each):
- **Lanjutkan perubahan**: do the new request; update the docs that held the old decision and write an ADR.
- **Tetap rencana awal**: keep the old decision; nothing changes.
- **Kompromi**: a concrete middle way, if one exists (e.g. "pakai IEEE hanya untuk versi jurnal, APA tetap untuk
  skripsi"). Leave it out if there is no real middle way.
- **Lainnya**: free answer or a question back.

Your recommendation depends on the facts: if the old reason still holds and the change is costly, recommend keeping
the plan; if the new request fixes a real problem, recommend the change. Say why in one sentence.

A kit safety rule (no secrets in git, no `--no-verify`, no fake citations, no pirated sources) is not negotiable:
explain the rule and offer the closest allowed alternative instead of a "Lanjutkan" option.

### Step 3: record

- "Lanjutkan" → ADR in `docs/decisions/` (title, old decision, new decision, why, date), update the source doc(s)
  (PRD/DESIGN/PROJECT/RESEARCH/PLAN), and add one line to `docs/PROGRESS.md`. Then do the work.
- "Tetap" → one line in `docs/PROGRESS.md` ("user kept <decision> on <date>") so it is not asked again for the
  same request.
- In wf-marathon the user is away: do NOT make the change. Log it as `CHANGE(Qn)` in PROGRESS with the three parts
  above, continue with the current plan, and ask when the user is back.
