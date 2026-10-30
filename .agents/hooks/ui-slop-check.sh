#!/bin/sh
# Workflow Kit — flags common AI-slop UI patterns.
# Usage: sh .agents/hooks/ui-slop-check.sh [files...]   (no args = staged files)
# Escape hatch: put "slop-ok: <reason>" on the same line (must be justified by docs/DESIGN.md).

EXT_RE='\.(tsx|jsx|ts|js|vue|svelte|astro|html|css|scss|blade\.php|dart)$'

list_files() {
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do printf '%s\n' "$f"; done
  else
    git diff --cached --name-only --diff-filter=ACMR 2>/dev/null
  fi
}

# rule-name|extended-regex (case-sensitive unless noted)
RULES='gradient|bg-gradient-to-|bg-linear-to-|bg-radial|bg-conic|linear-gradient\(|radial-gradient\(|conic-gradient\(
one-side-border|border-[lrse]-(4|8|\[([3-9]|[1-9][0-9])px\])
one-side-border|border-(left|right|inline-start|inline-end)(-width)?[[:space:]]*:[[:space:]]*([3-9]|[1-9][0-9])px
default-purple|(from|via|to|bg|text|border|ring)-(purple|violet|indigo|fuchsia|pink)-[0-9]{2,3}
glass-blur|backdrop-blur|backdrop-filter:[[:space:]]*blur|blur-2xl|blur-3xl
text-gradient|bg-clip-text|background-clip:[[:space:]]*text
heavy-radius-shadow|rounded-3xl|shadow-2xl
glow|shadow-\[0_0_|drop-shadow-\[0_0_|box-shadow:[[:space:]]*0[[:space:]]+0[[:space:]]+[0-9]+px'

EMOJI_OK=0
if printf 'x\n' | LC_ALL=C.UTF-8 grep -qP 'x' 2>/dev/null; then EMOJI_OK=1; fi

TMP_FILES=$(mktemp 2>/dev/null || echo "/tmp/wf-slop-$$")
list_files "$@" | grep -E "$EXT_RE" > "$TMP_FILES"

found=0
while IFS= read -r file; do
  [ -f "$file" ] || continue
  printf '%s\n' "$RULES" | while IFS='|' read -r name re; do
    grep -nE "$re" "$file" 2>/dev/null | grep -v 'slop-ok:' | while IFS= read -r hit; do
      printf '%s:%s  [%s]\n' "$file" "$(printf '%s' "$hit" | cut -d: -f1)" "$name"
    done
  done
  grep -niE 'lorem ipsum' "$file" 2>/dev/null | grep -v 'slop-ok:' | cut -d: -f1 | while IFS= read -r ln; do
    printf '%s:%s  [placeholder-text]\n' "$file" "$ln"
  done
  if [ "$EMOJI_OK" = 1 ]; then
    LC_ALL=C.UTF-8 grep -nP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' "$file" 2>/dev/null | grep -v 'slop-ok:' | cut -d: -f1 | while IFS= read -r ln; do
      printf '%s:%s  [emoji]\n' "$file" "$ln"
    done
  fi
done < "$TMP_FILES" > "$TMP_FILES.out"

if [ -s "$TMP_FILES.out" ]; then
  found=1
  echo "ui-slop-check: AI-slop UI patterns found (see .agents/knowledge/ui-ux.md):"
  cat "$TMP_FILES.out"
  echo "Fix them, or add 'slop-ok: <reason>' on the line if docs/DESIGN.md allows it."
fi
rm -f "$TMP_FILES" "$TMP_FILES.out"
exit $found
