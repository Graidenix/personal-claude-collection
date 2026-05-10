#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

removed=0

for cmd in "$REPO_DIR/.claude/commands"/*.md; do
  [[ -f "$cmd" ]] || continue
  link="$CLAUDE_DIR/commands/$(basename "$cmd")"
  if [[ -L "$link" ]]; then
    rm "$link"
    echo "  removed command: $(basename "$cmd")"
    ((removed++)) || true
  fi
done

for skill_dir in "$REPO_DIR/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  link="$CLAUDE_DIR/skills/$(basename "${skill_dir%/}")"
  if [[ -L "$link" ]]; then
    rm "$link"
    echo "  removed skill:   $(basename "${skill_dir%/}")"
    ((removed++)) || true
  fi
done

echo ""
echo "$removed item(s) removed."