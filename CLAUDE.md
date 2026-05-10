# Personal Claude Code Plugin

This repository is a personal plugin for Claude Code that stores custom skills and slash commands.

## Structure

```
personal-plugin/
├── .claude/
│   ├── commands/       # Custom slash commands (one .md file per command)
│   └── settings.json   # Hooks, permissions, and tool allowlists
├── skills/             # Skill definitions (one directory per skill)
│   └── <skill-name>/
│       └── SKILL.md
└── CLAUDE.md
```

## Commands

Slash commands live in `.claude/commands/`. Each `.md` file becomes a `/command-name` you can invoke in Claude Code.

## Skills

Skills live in `skills/<name>/SKILL.md`. Each skill has a YAML frontmatter block that controls when and how Claude invokes it, followed by the instructions Claude should follow.

### Skill frontmatter fields

| Field | Purpose |
|---|---|
| `name` | Skill identifier |
| `description` | When Claude auto-triggers this skill |
| `allowed-tools` | Pre-approved tools (no permission prompt) |
| `argument-hint` | Autocomplete hint shown after `/skill-name` |

## Usage

To use this plugin across all your projects, symlink or copy commands to `~/.claude/commands/` and skills to `~/.claude/skills/`.