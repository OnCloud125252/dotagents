# .claude Template

**A batteries-included starter kit for extending Claude Code with custom commands, skills, hooks, and status line integrations.**

## Table of Contents

- [Overview](#overview)
- [Commands](#commands)
- [Skills](#skills)
- [Hooks](#hooks)
- [Status Line](#status-line)
- [AGENTS.md Templates](#agentsmd-templates)
- [Gemini CLI Commands](#gemini-cli-commands)
- [Helpers](#helpers)
- [FAQs](#faqs)
- [Installation](#installation)

## Overview

This repository is a ready-to-use `.claude` directory template. You can clone it and symlink (or copy) the pieces you need into your own `~/.claude` to get a fully configured Claude Code environment with:

- **21 slash commands** for git workflows, PR automation, worktree management, and more
- **12 skills** that trigger contextually during conversations
- **3 hooks** for notifications and session persistence
- **A custom status line** showing git state, working directory, and last prompt

```
.
├── commands/          # Slash commands (/git:commit, /pr:create, etc.)
├── skills/            # Contextual agent skills
├── hooks/             # Event-driven shell scripts
├── claude-statusline/ # Terminal status line scripts
├── agentsmd-templates/# Reusable AGENTS.md snippets
├── gemini-commands/   # Auto-converted Gemini CLI equivalents
├── helpers/           # Shared utility scripts
├── GLOBAL_AGENTS.md   # Coding conventions & workflow rules
└── dependency.md      # External tool requirements
```

## Commands

Slash commands live in [`commands/`](./commands/) as Markdown files with YAML frontmatter. Each declares its allowed tools, preferred model, and step-by-step instructions.

| Namespace | Commands | What they do |
|-----------|----------|--------------|
| `git/` | `commit`, `pull`, `push`, `changelog`, `version`, `issue` | Full git workflow from commits to releases |
| `pr/` | `create`, `resolve` | Push branches, open PRs, resolve review threads |
| `worktree/` | `create`, `merge`, `cleanup` | Manage git worktrees in `.claude/worktrees/` |
| `docs/` | `agentsmd`, `update` | Create/update AGENTS.md and sync docs with code |
| `opsx/` | `propose`, `apply`, `explore`, `archive` | OpenSpec experimental workflow |
| `code/` | `react-doctor` | Scan React codebases for issues (0-100 score) |
| _(root)_ | `search`, `auto-resolve`, `organize-dir` | Web search, DevOps automation, directory cleanup |

Commands use YAML frontmatter to declare metadata:

```yaml
---
name: Create Commits
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*)
description: Create commits for recent changes.
model: claude-sonnet-4-6
---
```

## Skills

Skills live in [`skills/`](./skills/), each in its own directory with a `SKILL.md` file. They activate contextually based on trigger conditions rather than explicit invocation.

| Skill | Triggers when... |
|-------|-----------------|
| [`commit`](./skills/commit/) | Creating git commits |
| [`readme`](./skills/readme/) | Writing or editing READMEs |
| [`docs-writer`](./skills/docs-writer/) | Working on documentation files |
| [`cli-output-style`](./skills/cli-output-style/) | Writing shell scripts with terminal output |
| [`react-best-practices`](./skills/react-best-practices/) | Working with React/Next.js code |
| [`grafana-dashboards`](./skills/grafana-dashboards/) | Building monitoring dashboards |
| [`claude-api`](./skills/claude-api/) | Code imports Anthropic SDK |
| [`humanizer`](./skills/humanizer/) | Editing text to sound more natural |
| [`openspec-*`](./skills/openspec-propose/) | Using the OpenSpec workflow |
| [`find-skills`](./skills/find-skills/) | Looking for new capabilities |

## Hooks

Hook scripts in [`hooks/`](./hooks/) respond to Claude Code lifecycle events. They receive JSON event data via stdin and are configured in `settings.json`.

| Hook | Event | What it does |
|------|-------|-------------|
| [`notify.sh`](./hooks/notify.sh) | Session stop | Sends a macOS notification with an LLM-generated summary of what happened |
| [`load-recent-work.sh`](./hooks/load-recent-work.sh) | Session start | Loads prior session context so the agent remembers what you were working on |
| [`update-recent-work.sh`](./hooks/update-recent-work.sh) | Session stop | Saves a summary of the current session for next time |

The notification hook uses [growlrrr](https://github.com/moltenbits/growlrrr) for native macOS notifications with a custom Claude icon, and clicking the notification brings your terminal to the foreground.

## Status Line

Scripts in [`claude-statusline/`](./claude-statusline/) power the terminal status line that appears during Claude Code sessions.

| Script | Purpose |
|--------|---------|
| [`statusline.sh`](./claude-statusline/statusline.sh) | Main entry point, pipes session JSON to `ccstatusline` |
| [`short-pwd.sh`](./claude-statusline/short-pwd.sh) | Abbreviates long directory paths, highlights worktree directories |
| [`last-user-input.sh`](./claude-statusline/last-user-input.sh) | Extracts your last prompt for context display |

## AGENTS.md Templates

Reusable snippets in [`agentsmd-templates/`](./agentsmd-templates/) that you can compose into any project's AGENTS.md:

- [`coding-standards.md`](./agentsmd-templates/coding-standards.md) -- Style preferences (indentation, naming, imports)
- [`workflow.md`](./agentsmd-templates/workflow.md) -- Development workflow guidelines
- [`git-workflow.md`](./agentsmd-templates/git-workflow.md) -- Git branching and merge practices
- [`git-commit-conventions.md`](./agentsmd-templates/git-commit-conventions.md) -- Conventional commit format
- [`nodejs.md`](./agentsmd-templates/nodejs.md) -- Node.js/Bun-specific conventions
- [`ios.md`](./agentsmd-templates/ios.md) -- iOS development guidelines

## Gemini CLI Commands

Auto-generated TOML equivalents of the slash commands for Google's Gemini CLI, stored in [`gemini-commands/`](./gemini-commands/). These are produced by the `convert-to-gemini-command` local command in [`.claude/commands/`](./.claude/commands/convert-to-gemini-command.md).

## Helpers

Shared utility scripts in [`helpers/`](./helpers/):

- [`summarize.sh`](./helpers/summarize.sh) -- Uses OpenAI GPT-4 Nano with function calling to generate concise notification summaries. Falls back gracefully when the API key is missing.

## FAQs

#### How do I add a new slash command?

Create a `.md` file in the appropriate `commands/` subdirectory. Use YAML frontmatter to declare `name`, `description`, `allowed-tools`, and optionally `model`. Look at any existing command for the pattern.

#### Can I use only some parts of this template?

Yes. Each directory is self-contained. You can symlink just `commands/git/` into your `.claude/commands/` or copy individual skills without pulling in the entire template.

#### How do the hooks persist session context?

On session stop, `update-recent-work.sh` writes a summary to `.claude/RECENT_WORK.md`. On the next session start, `load-recent-work.sh` reads it back so the agent has context about your prior work.

#### Do I need all the external dependencies?

Only for the features you use. The core commands and skills work without any external tools. Dependencies like `growlrrr` (notifications), `ccstatusline` (status line), and `jq` (JSON parsing in hooks) are only needed if you enable those specific features.

#### How do I convert commands for Gemini CLI?

Run the `/convert-to-gemini-command` local command. It reads all `.md` commands and outputs `.toml` equivalents in `gemini-commands/`.

## Installation

### Prerequisites

macOS with [Homebrew](https://brew.sh) installed.

### Quick Setup

```bash
# Clone the template
git clone <repo-url> ~/.agents

# Install core dependencies
brew install jq trash ripgrep bun

# (Optional) Notifications
brew tap moltenbits/tap && brew install growlrrr
grrr authorize
grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png

# (Optional) Status line
bunx -y ccstatusline@latest
```

Then symlink or copy the directories you want into `~/.claude/`:

```bash
# Example: link commands and skills
ln -s ~/.agents/commands ~/.claude/commands
ln -s ~/.agents/skills ~/.claude/skills
```

For the full dependency breakdown and troubleshooting, see [`dependency.md`](./dependency.md).
