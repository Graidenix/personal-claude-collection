---
name: renew-docs
description: Keep CLAUDE.md ≤175 lines by extracting long descriptions into docs/ files with reference links, then sync docs to reflect recent code changes.
---

## Phase 1 — Slim CLAUDE.md (if needed)

Read CLAUDE.md and count its lines. If ≤175, skip to Phase 2.

Otherwise, trim it:

**What stays in CLAUDE.md (non-negotiable):**
- Project header and quick-start commands — unchanged.
- Any section whose primary purpose is rules, constraints, or conventions (coding standards, naming rules, architectural decisions, patterns to follow or avoid) — keep verbatim.
- Short reference sections (≤10 lines each) — keep as-is.
- Reference links to docs/ files added below.

**What moves to docs/ files:**
- Detailed reference tables (component lists, route tables, type definitions, DB schema) → `docs/REFERENCE.md`
- Deep architectural prose (file tree, subsystem descriptions, data flow, screen-by-screen descriptions) → `docs/ARCHITECTURE.md`
- Any other large block of descriptive (not prescriptive) content — pick the most fitting docs/ file or create a new one (e.g. `docs/SCREENS.md`, `docs/HOOKS.md`).

**How to decide what stays vs what moves:**
- Rule prose (the written constraint: "never use X", "always do Y") → stay in CLAUDE.md.
- Code snippets illustrating those rules (correct/incorrect patterns, before/after examples) → move to docs/.
- Descriptive catalogues (component tables, route lists, type definitions, file trees) → move to docs/.

**Replacement pattern in CLAUDE.md:** after each condensed section, add one line:
`→ [Section title](docs/FILENAME.md)`

After rewriting, verify CLAUDE.md is ≤175 lines. If still over, condense prose summaries further (never cut rules).

---

## Phase 2 — Sync docs to recent changes

Identify what has changed in the codebase since the docs were last written:
- Run `git log --oneline -20` to surface recent commits.
- For each commit that touches source files, check whether CLAUDE.md or any `docs/*.md` file is now stale or missing coverage.

For each gap found:
- If the change affects rules or conventions → update CLAUDE.md.
- If the change affects architecture, components, screens, hooks, or reference data → update the relevant `docs/*.md` file.
- If a new subsystem or major feature was added with no docs entry → add a concise entry to the appropriate file.

Do not invent content — only document what is observable in the code.

---

## Phase 3 — Update README.md (only if it exists)

Check if README.md exists in the project root. If it does not, skip this phase entirely.

If it exists, rewrite it using rich GitHub-flavored markdown: badges, emoji section icons, feature lists, collapsible sections (`<details>`), tables, and code blocks where appropriate. Make it visually appealing and catchy for a public audience — this is a showcase document, not internal docs. Base content on what is observable in the codebase and the current CLAUDE.md/docs/ files; do not invent features.

---

## Output

Be extremely concise, sacrifice grammar for concision. Report:
1. Phase 1 ran or skipped + before/after line count.
2. Files changed in Phase 2, one-line each.