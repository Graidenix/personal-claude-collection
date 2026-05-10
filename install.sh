#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Graidenix/personal-claude-collection.git"
CLONE_DIR="${PERSONAL_PLUGIN_DIR:-$HOME/Developer/personal-plugin}"
CLAUDE_DIR="$HOME/.claude"

# Detect curl-pipe mode: BASH_SOURCE[0] is not a real file on disk
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
  if [[ -d "$CLONE_DIR/.git" ]]; then
    echo "Updating existing clone at $CLONE_DIR..."
    git -C "$CLONE_DIR" pull --ff-only
  else
    echo "Cloning to $CLONE_DIR..."
    git clone "$REPO_URL" "$CLONE_DIR"
  fi
  REPO_DIR="$CLONE_DIR"
else
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

linked=0

if [[ -e "$CLAUDE_DIR/CLAUDE.md" && ! -L "$CLAUDE_DIR/CLAUDE.md" ]]; then
  echo "  warning: ~/.claude/CLAUDE.md exists and is not a symlink — skipping global rules (back it up and remove it to let install manage it)"
else
  ln -sf "$REPO_DIR/rules/GLOBAL.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "  linked global rules: CLAUDE.md"
  ((linked++)) || true
fi

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
