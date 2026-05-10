# personal-plugin

Personal Claude Code plugin — custom skills and slash commands, synced across machines via git.

## Setup on a new machine

```bash
git clone <your-repo-url> ~/Developer/personal-plugin
cd ~/Developer/personal-plugin
chmod +x install.sh
./install.sh
```

That's it. Restart Claude Code and your commands and skills will be available globally.

## Updating

```bash
git pull
# No reinstall needed — symlinks keep everything in sync automatically.
```

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