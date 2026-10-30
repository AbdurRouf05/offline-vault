#!/bin/sh
# Workflow Kit — checks that the mermaid erDiagram and the DBML block in docs/DATABASE.md describe the SAME schema:
# same tables, same column names per table, same relationships (table pairs). Types are not compared
# (mermaid types are simpler); DBML may carry extra detail (notes, indexes, defaults).
# Usage: sh .agents/hooks/db-schema-check.sh [path/to/DATABASE.md]
FILE="${1:-docs/DATABASE.md}"
[ -f "$FILE" ] || { echo "db-schema-check: $FILE not found, skipped."; exit 0; }

TMP=$(mktemp -d 2>/dev/null || { mkdir -p "/tmp/wf-db-$$"; echo "/tmp/wf-db-$$"; })
tr -d '\r' < "$FILE" > "$TMP/src"

# Mermaid: "  name {" opens a table, "type col [PK|FK|UK] [\"comment\"]" are columns, "A ||--o{ B : label" relations.
awk '
  /^```mermaid/ { inm=1; next }
  inm && /^```/ { inm=0; next }
  !inm { next }
  /^[[:space:]]*erDiagram/ { next }
  tbl != "" && /^[[:space:]]*}/ { tbl=""; next }
  tbl != "" && NF >= 2 { print "C " tbl "." $2; next }
  /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\{/ { t=$1; sub(/\{.*/, "", t); tbl=t; print "T " tbl; next }
  /--|\.\./ && NF >= 3 {
    a=$1; b=$3; if (a > b) { x=a; a=b; b=x } print "R " a "-" b
  }
' "$TMP/src" | sort -u > "$TMP/mermaid"

# DBML: "Table name {" (optional "as alias" / quotes), columns "name type [..]", "Ref: a.x > b.y" or inline [ref: > b.y].
awk '
  /^```dbml/ { ind=1; next }
  ind && /^```/ { ind=0; next }
  !ind { next }
  /^[[:space:]]*Table[[:space:]]/ { t=$2; gsub(/["{]/, "", t); tbl=t; print "T " tbl; next }
  tbl != "" && /^[[:space:]]*(Indexes|indexes|Note|note)/ && /\{/ { skip=1; next }
  skip && /^[[:space:]]*}/ { skip=0; next }
  skip { next }
  tbl != "" && /^[[:space:]]*}/ { tbl=""; next }
  tbl != "" && NF >= 2 && $1 !~ /^\/\// {
    c=$1; gsub(/"/, "", c); print "C " tbl "." c
    if (match($0, /ref:[[:space:]]*[<>-]+[[:space:]]*[A-Za-z_"]+/)) {
      r=substr($0, RSTART, RLENGTH); sub(/ref:[[:space:]]*[<>-]+[[:space:]]*/, "", r); gsub(/"/, "", r)
      a=tbl; b=r; if (a > b) { x=a; a=b; b=x } print "R " a "-" b
    }
    next
  }
  /^[[:space:]]*Ref/ {
    line=$0; sub(/^[^:]*:[[:space:]]*/, "", line); gsub(/"/, "", line)
    n=split(line, p, /[[:space:]]*[<>-]+[[:space:]]*/)
    if (n >= 2) { split(p[1], l, "."); split(p[2], r2, "."); a=l[1]; b=r2[1]; if (a > b) { x=a; a=b; b=x } print "R " a "-" b }
  }
' "$TMP/src" | sort -u > "$TMP/dbml"

status=0
if [ ! -s "$TMP/mermaid" ] || [ ! -s "$TMP/dbml" ]; then
  echo "db-schema-check: $FILE needs both a \`\`\`mermaid erDiagram block and a \`\`\`dbml block."
  status=1
elif ! cmp -s "$TMP/mermaid" "$TMP/dbml"; then
  echo "db-schema-check: mermaid and DBML in $FILE are out of sync (T=table, C=column, R=relationship):"
  comm -23 "$TMP/mermaid" "$TMP/dbml" | sed 's/^/  only in mermaid: /'
  comm -13 "$TMP/mermaid" "$TMP/dbml" | sed 's/^/  only in DBML:    /'
  status=1
fi
rm -rf "$TMP"
exit $status
