#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

linked=0

for cmd in "$REPO_DIR/.claude/commands"/*.md; do
  [[ -f "$cmd" ]] || continue
  name="$(basename "$cmd")"
  ln -sf "$cmd" "$CLAUDE_DIR/commands/$name"
  echo "  linked command: $name"
  ((linked++)) || true
done

for skill_dir in "$REPO_DIR/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  ln -sf "${skill_dir%/}" "$CLAUDE_DIR/skills/$name"
  echo "  linked skill:   $name"
  ((linked++)) || true
done

echo ""
echo "$linked item(s) linked. Restart Claude Code to pick up changes."