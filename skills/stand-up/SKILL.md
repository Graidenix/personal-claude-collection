---
name: stand-up
description: Generate a daily standup report from git history and uncommitted changes for the current user. Use when the user asks for a standup, daily summary, or what they worked on.
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git config:*)
---

# Daily Stand-up Generator

Generate a concise standup report from git history and current working state.

## Step 1 — Determine time window

Get today's day of week:
```
date +%A
```

- **Monday** → look back to Friday (72h window: `--since="3 days ago"`)
- **Tuesday–Friday** → last 24h (`--since="24 hours ago"`)
- **Saturday or Sunday** → output: `No standup needed today.` and stop

## Step 2 — Get current git user

```
git config user.email
```

Use this email to filter commits with `--author`.

## Step 3 — Collect committed changes

```
git log --since="<window>" --author="<email>" --oneline --no-merges
```

If no commits and no uncommitted changes exist → output: `Nothing to report for this period.` and stop.

## Step 4 — Collect uncommitted changes

```
git status --short
git diff --stat HEAD
```

Treat staged + unstaged changes as signals for **what's in progress** (not done).

## Step 5 — Synthesize the report

### Done (committed work)

- Group commits that touch the same feature/area into a single bullet — do not list every commit separately
- Skip trivial-only commits: typo fixes, version bumps, merge commits, linter/format-only changes — **unless they are the only commits in the window**
- Maximum **7 bullets** for done items
- Each bullet: one sentence, past tense, plain English — describe the outcome, not the git command

### In Progress (uncommitted work)

- Infer from `git status` and `git diff --stat` what is currently being worked on
- Maximum **3 bullets**, present tense ("Working on…", "Updating…")
- If nothing uncommitted → omit this section entirely

## Output Format

```
**Done:**
• <sentence>
• <sentence>
...

**In Progress:**
• <sentence>
...
```

No headers, no preamble, no trailing summary. Bullets only. Total items across both sections: max 10.
