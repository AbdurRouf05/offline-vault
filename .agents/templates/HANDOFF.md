# Handoff

> Working memory for the next session or the next model. Read this FIRST, then `docs/PROGRESS.md`.
> Overwrite it (do not append) after every completed task and whenever the chat gets long.
> Keep it under ~150 lines: facts and pointers, not a diary. Full user messages live in `docs/CHATLOG.md`.

**Updated:** YYYY-MM-DD HH:MM · **Model/tool:** <e.g. Gemini in Antigravity> · **Branch:** <branch> · **Last commit:** <hash subject>

## TL;DR
<!-- 3-5 lines. A new model that reads only this section must know what the project is, where we are, and what to do next. -->
- Project: <one line: what it is, for whom>
- Now: <what we are in the middle of>
- Next: <the very next action>
- Watch out: <the one thing most likely to go wrong>

## What the user asked for (current request)
<!-- The request in progress, in the user's own words where it matters. Quote short key sentences. -->
- "<short quote of the key sentence>" (YYYY-MM-DD)
- Interpreted as: <what you understood, incl. scope limits>

## State
- Done in this request: <items, each with the file or commit that proves it>
- In flight: <the exact file / function / step where work stopped, and what is half-done>
- Not started: <remaining items of this request>
- Verified: <command run -> result>; Not verified: <what still needs checking>

## Next steps
1. <concrete action, with the file to open>
2. <...>
3. <...>

## Decisions and user preferences
<!-- Things the user decided or prefers that a new model would otherwise get wrong. Link ADRs. -->
- <decision> - why: <reason> (YYYY-MM-DD, ADR-NNNN if any)
- <preference, e.g. "replies in Indonesian, no emoji", "always ask with the question tool">

## Gotchas and dead ends
<!-- What was tried and failed, environment quirks, commands that need special flags. Saves the next model hours. -->
- <tried X, failed because Y - do Z instead>

## Open questions
- <question waiting for the user> (asked YYYY-MM-DD)

## Read first
<!-- The few files that matter for the next step, with why. -->
- `<path>` - <why>
