# personal-plugin

> Personal Claude Code plugin — custom skills and slash commands, synced across machines via git.

---

## 🚀 Install

One command — no clone needed:

```bash
curl -sSL https://raw.githubusercontent.com/Graidenix/personal-claude-collection/main/install.sh | bash
```

Clones to `~/Developer/personal-plugin` and symlinks everything into `~/.claude/`. Restart Claude Code after.

> **Custom location:** set `PERSONAL_PLUGIN_DIR` before running:
> ```bash
> PERSONAL_PLUGIN_DIR=~/code/my-plugin curl -sSL ... | bash
> ```

---

## 🔄 Update

```bash
git pull
# or re-run the one-liner — detects existing clone and pulls automatically
```

Symlinks stay in sync — no reinstall needed.

## 🗑️ Uninstall

```bash
./uninstall.sh
```

Removes only the symlinks; leaves `~/.claude/` config untouched.

---

## 🧠 Skills

Auto-triggered personas Claude adopts based on project context or keywords.

<details>
<summary><b>Framework experts</b></summary>

| Skill | Trigger | What it does |
|---|---|---|
| `angular-expert` | `@angular/core` in package.json | Audits Angular version, enforces signals/standalone/OnPush/Material 3 |
| `react-expert` | `react` in package.json | Enforces hooks, context, exhaustive-deps, ErrorBoundary patterns |
| `bun-hono` | `hono` in package.json | Enforces Bun-native APIs, zod-openapi, typed middleware, 422 errors |

</details>

<details>
<summary><b>Domain experts</b></summary>

| Skill | Trigger | What it does |
|---|---|---|
| `seo-expert` | SEO/indexing questions | Audits meta tags, structured data, Core Web Vitals, AI engine visibility |
| `photo-expert` | Photography questions | Composition, lighting, posing (incl. boudoir/nude), camera technique |
| `trainer` | Fitness/gym questions | Exercise form, program design, nutrition timing, recovery, sports science |

</details>

<details>
<summary><b>Workflow tools</b></summary>

| Skill | Trigger | What it does |
|---|---|---|
| `qa-engineer` | Editing JSX/TSX/Angular templates | Auto-adds `data-test-id` attributes when test-id mode is on |
| `code-review` | "review code" / "check this file" | Senior dev review: bugs, perf, edge cases, style, debug noise |
| `stand-up` | "standup" / "what did I work on" | Daily report from git history + uncommitted changes (Mon lookback to Fri) |
| `suno-expert` | Music/song creation requests | Writes Suno v5.5-ready lyrics, style prompt, and title as a senior music producer |
| `caveman` | "caveman mode" / "less tokens" | ~75% token reduction — full technical accuracy, no fluff |

</details>

---

## ⚡ Slash Commands

Invoke with `/command-name` in any Claude Code session.

| Command | What it does |
|---|---|
| `/git-message` | Generates a single commit message sentence from staged diff (runs on Haiku for speed) |
| `/grill-me` | Relentlessly interviews you about a plan until reaching shared understanding |
| `/renew-docs` | Slims CLAUDE.md ≤175 lines, syncs docs to recent commits, refreshes README |
| `/test-id [on\|off]` | Toggles `qa-engineer` auto `data-test-id` injection |
| `/tsx-style [path]` | Reformats TSX files to match project code style conventions |

---

## 🏗️ Structure

```
personal-plugin/
├── .claude/
│   ├── commands/       # Slash commands (/command-name)
│   └── settings.json   # Shared permissions and hooks
├── skills/             # Auto-trigger skills
│   └── <name>/
│       └── SKILL.md
├── install.sh
├── uninstall.sh
└── CLAUDE.md
```

---

## ➕ Adding a slash command

Create `.claude/commands/<name>.md`:

```markdown
---
description: One-line description shown in /help
argument-hint: "[optional arg]"
allowed-tools: Bash, Read
---

Instructions for Claude. Reference arguments with $ARGUMENTS.
```

## ➕ Adding a skill

Create `skills/<name>/SKILL.md`:

```markdown
---
name: name
description: When Claude should auto-trigger this skill
allowed-tools: Read, Bash
argument-hint: "[target]"
---

Instructions Claude follows when the skill is invoked.
```

### Skill frontmatter fields

| Field | Purpose |
|---|---|
| `name` | Skill identifier |
| `description` | Auto-trigger condition (checked against project context + user messages) |
| `allowed-tools` | Tools pre-approved — no permission prompt |
| `argument-hint` | Autocomplete hint shown after `/skill-name` |
