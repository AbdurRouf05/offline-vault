#!/bin/sh
# Workflow Kit — pre-commit hook: anti-slop UI check + secret scan (if gitleaks is installed).
ROOT=$(git rev-parse --show-toplevel)
status=0

sh "$ROOT/.agents/hooks/ui-slop-check.sh" || status=1

# Database docs: schema/migration changes must update docs/DATABASE.md, and its mermaid + DBML must match.
if [ -f "$ROOT/docs/DATABASE.md" ]; then
  STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
  SCHEMA_RE='(migrations?/|schema\.prisma$|/schema\.(ts|js)$|drizzle/|alembic/versions/|models\.py$|database/migrations/)'
  if printf '%s\n' "$STAGED" | grep -qE "$SCHEMA_RE" && ! printf '%s\n' "$STAGED" | grep -qx 'docs/DATABASE.md'; then
    echo "pre-commit: database schema changed but docs/DATABASE.md is not staged (update mermaid + DBML + migration log)."
    status=1
  fi
  sh "$ROOT/.agents/hooks/db-schema-check.sh" "$ROOT/docs/DATABASE.md" || status=1
fi

if command -v gitleaks >/dev/null 2>&1; then
  # gitleaks v8.19+ uses "git --pre-commit --staged"; older versions use "protect --staged".
  if gitleaks git --help >/dev/null 2>&1; then
    gitleaks git --pre-commit --staged --redact -v || status=1
  else
    gitleaks protect --staged --redact -v || status=1
  fi
else
  echo "pre-commit: gitleaks not installed, secret scan skipped (see .agents/knowledge/quality-gates.md)."
fi

exit $status
