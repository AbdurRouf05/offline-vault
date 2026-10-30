# Chat log

> Append-only record of the conversation, so a new session can see the whole history.
> One entry per user message: the message copied in full (verbatim, typos included), then 1-2 lines on
> what the AI did. Newest entry at the bottom. Never edit or summarize old entries.
> Do not copy secrets: replace passwords, tokens, and keys with `[redacted]`.
> When this file passes ~1500 lines, move whole months to `docs/archive/CHATLOG-YYYY-MM.md`
> and leave a line here: `Earlier entries: docs/archive/`.

<!-- Entry format:

### YYYY-MM-DD HH:MM · <model/tool if known>
**User:**
> <message, verbatim; keep line breaks; long pasted logs or code: keep the first ~20 lines and write [truncated: N lines of X]>

**AI:** <what was done or answered, 1-2 lines; files or commits touched>

-->
