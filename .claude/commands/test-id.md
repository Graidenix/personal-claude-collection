---
description: Toggle the qa-engineer skill on or off to auto-add data-test-id attributes when editing component templates
argument-hint: "[on|off]"
allowed-tools: Bash
---

Manage test-id state for the current project via `.claude/test-id.state`.

Based on $ARGUMENTS:

- `on`  → run:
  ```bash
  mkdir -p .claude && echo "on" > .claude/test-id.state
  grep -qxF '.claude/test-id.state' .gitignore 2>/dev/null || echo '.claude/test-id.state' >> .gitignore
  ```
  Reply only: `test-id: ON`

- `off` → run `mkdir -p .claude && echo "off" > .claude/test-id.state` — reply only: `test-id: OFF`

- (none) → run `cat .claude/test-id.state 2>/dev/null || echo "off"` and report current state