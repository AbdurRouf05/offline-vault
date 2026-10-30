# Git & Commits

## Commits

- **Conventional Commits**: `type(scope): summary` — imperative, lowercase, ≤ 72 chars, no period.
  Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`, `style`.
  Examples: `feat(orders): add CSV export`, `fix(auth): reject expired reset tokens`.
- Body (optional): *why* the change was needed, not a list of files.
- Commit after each completed, verified step — small commits make reverting easy.
- Code commits also stage `docs/PROGRESS.md` (enforced by `.agents/hooks/commit-msg.sh`; skip only with a real reason:
  `WF_SKIP_PROGRESS=1`).
- Never commit: `.env`, secrets, build outputs, `node_modules`/`vendor`/`.venv`, large binaries, local IDE settings.

## Atomic commits

An atomic commit is **one complete logical change**, nothing more, nothing less. Like a save point in a game.

A commit is atomic when:
1. **One purpose** — describable in one line without "and" (`feat(cart): add quantity input`).
2. **Complete** — the project builds and verify passes at this commit (no "WIP, broken").
3. **Revertable alone** — `git revert <hash>` removes exactly that change and nothing else.
4. **Nothing unrelated** — no drive-by formatting, renames, or debug code.

How:
- Plan steps so each one is a commit (`wf-feature` Step 4).
- Mixed changes in the working tree → stage selectively: `git add <file>` or `git add -p` (pick hunks), then
  `git diff --cached` to check exactly what will be committed.
- Feature + refactor needed? Refactor first (its own commit, behavior unchanged), then the feature.
- Too big to describe in one line → split it.

Bad: `update stuff` (12 files: feature + bug fix + formatting).
Good: `refactor(cart): extract price calculation` → `feat(cart): add quantity input` → `fix(cart): round totals to rupiah`.

## Branches

- `main` is always working and deployable.
- Work on short-lived branches: `feat/<short-name>`, `fix/<short-name>`, `chore/<short-name>`.
- Merge through a PR when the project uses one (even solo — CI runs, and it's a natural review point).

## Safety rules for the agent

- Check `git status` before starting and before committing. Don't commit files you didn't intend to change.
- **Ask first** before: `push --force`, `reset --hard`, `rebase` on shared branches, deleting branches, `clean -fd`, or discarding uncommitted changes that you didn't make.
- Never skip hooks (`--no-verify`) to get a commit through. Fix what the hook reports.
- If a secret was committed: stop, tell the user, rotate the secret. Rewriting history alone doesn't make it safe.

## Versioning & tags

- Semantic versioning `MAJOR.MINOR.PATCH`. Tag releases `vX.Y.Z`. See skill `wf-release`.
