# personal-plugin

Personal Claude Code plugin — custom skills and slash commands, synced across machines via git.

## Setup on a new machine

One command — no clone needed:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/personal-plugin/main/install.sh | bash
```

Clones the repo to `~/Developer/personal-plugin` and symlinks everything into `~/.claude/`. Restart Claude Code after.

> To clone elsewhere, set `PERSONAL_PLUGIN_DIR` before running:
> ```bash
> PERSONAL_PLUGIN_DIR=~/code/personal-plugin curl -sSL ... | bash
> ```

## Updating

```bash
# From the cloned repo:
git pull

# Or re-run the one-liner — it detects an existing clone and does git pull automatically.
```

No reinstall needed after `git pull` — symlinks keep everything in sync.

## Uninstall

```bash
./uninstall.sh
```

Removes only the symlinks; leaves your `~/.claude/` config untouched.

## Adding a slash command

Create `.claude/commands/<name>.md`:

```markdown
---
description: One-line description shown in /help
argument-hint: "[optional arg]"
allowed-tools: Bash, Read
---

Instructions for Claude. Reference arguments with $ARGUMENTS.
```

Run `/name` in Claude Code.

## Adding a skill

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

## Structure

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