#!/bin/sh
# Workflow Kit — installs git hooks that call .agents/hooks/*.sh
# Safe: never overwrites a hook it did not create. If you use lefthook/husky, see quality-gates.md instead.
git rev-parse --git-dir >/dev/null 2>&1 || { echo "install-hooks: not a git repo, skipped."; exit 0; }
HOOKS_DIR=$(git rev-parse --git-path hooks)
mkdir -p "$HOOKS_DIR"

for name in pre-commit commit-msg; do
  target="$HOOKS_DIR/$name"
  if [ -f "$target" ] && ! grep -q '# Workflow Kit' "$target"; then
    echo "install-hooks: $target exists (not ours) - skipped. Call .agents/hooks/$name.sh from your hook manager."
    continue
  fi
  cat > "$target" <<EOF
#!/bin/sh
# Workflow Kit
exec sh "\$(git rev-parse --show-toplevel)/.agents/hooks/$name.sh" "\$@"
EOF
  chmod +x "$target" 2>/dev/null
  echo "install-hooks: $name installed"
done
