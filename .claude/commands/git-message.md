---
model: claude-haiku-4-5-20251001
---

Run `git status` and `git diff` (including staged changes via `git diff --cached`), then reply with **only** a single commit message sentence — nothing else, no explanation, no markdown, no prefix like "Here is…".

Follow these rules for the message:
- Use conventional commits format: `type: short description` (e.g. `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `style:`, `test:`)
- Max 72 characters total
- Lowercase after the colon
- Present tense, imperative mood ("add", not "added" or "adds")
- Describe *what changed and why* in the most meaningful way possible
- If changes span multiple concerns, pick the dominant one