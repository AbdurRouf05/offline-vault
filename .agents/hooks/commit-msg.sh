#!/bin/sh
# Workflow Kit — commit-msg hook.
# 1) Conventional Commits format, first line <= 72 chars.
# 2) Code commits must also stage docs/PROGRESS.md (memory for the next AI session).
#    Bypass only for a real reason: WF_SKIP_PROGRESS=1 git commit ...
# 3) Non-blocking reminder when docs/HANDOFF.md is 5+ commits old.

MSG_FILE="$1"
FIRST=$(sed -n '/^[^#]/{p;q;}' "$MSG_FILE")

case "$FIRST" in
  Merge*|Revert*|fixup!*|squash!*|amend!*) exit 0 ;;
esac

TYPES='feat|fix|refactor|perf|test|docs|style|build|ci|chore|revert'
if ! printf '%s\n' "$FIRST" | grep -qE "^($TYPES)(\([A-Za-z0-9._/-]+\))?!?: .+"; then
  echo "commit-msg: use Conventional Commits, e.g. 'feat(cart): add quantity input'"
  echo "  allowed types: $TYPES"
  echo "  got: $FIRST"
  exit 1
fi
if [ "${#FIRST}" -gt 72 ]; then
  echo "commit-msg: first line is ${#FIRST} chars (max 72)."
  exit 1
fi

# 3) Reminder only (never blocks): docs/HANDOFF.md not refreshed for 5+ commits.
if [ -f docs/HANDOFF.md ] && ! git diff --cached --name-only | grep -qx 'docs/HANDOFF.md'; then
  LAST=$(git log -1 --format=%H -- docs/HANDOFF.md 2>/dev/null)
  if [ -n "$LAST" ]; then
    SINCE=$(git rev-list --count "$LAST..HEAD" 2>/dev/null || echo 0)
    if [ "$SINCE" -ge 5 ]; then
      echo "commit-msg: note - docs/HANDOFF.md was last committed $SINCE commits ago."
      echo "  Refresh it soon (skill wf-handoff, Save mode) so the next session does not lose context."
    fi
  fi
fi

[ "${WF_SKIP_PROGRESS:-0}" = 1 ] && exit 0
TYPE=$(printf '%s' "$FIRST" | sed -E 's/^([a-z]+).*/\1/')
case "$TYPE" in docs|style|ci) exit 0 ;; esac
[ -f docs/PROGRESS.md ] || exit 0

STAGED=$(git diff --cached --name-only)
CODE=$(printf '%s\n' "$STAGED" | grep -vE '^(docs/|\.agents/|\.github/|README|CHANGELOG|AGENTS\.md|CLAUDE\.md)' | grep -v '^$')
if [ -n "$CODE" ] && ! printf '%s\n' "$STAGED" | grep -qx 'docs/PROGRESS.md'; then
  echo "commit-msg: code changed but docs/PROGRESS.md is not staged."
  echo "  Add a log line + update 'Next steps' in docs/PROGRESS.md, then: git add docs/PROGRESS.md"
  exit 1
fi
exit 0
