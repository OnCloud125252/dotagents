# Project Dependencies

All external tools required by this environment. Install everything with the [quick setup](#quick-setup) or follow individual sections below.

## Quick Setup

```bash
# Package manager (prerequisite)
# Install Homebrew if not present: https://brew.sh

# Core CLI tools
brew install git gh jq curl trash bun node pnpm

# Claude CLI
npm install -g @anthropic-ai/claude-code

# OpenSpec CLI
npm install -g openspec

# Notifications
brew tap moltenbits/tap
brew install growlrrr
grrr authorize
grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png

# Status line
bunx -y ccstatusline@latest

# Environment variables
# Set CLAUDE_CODE_SUMMARIZER_API_KEY to an OpenAI API key for notification summaries
```

---

## Bun

JavaScript runtime. Provides `bunx` for running npm packages without global install.

- **Install:** `brew install bun`
- **Used by:** `claude-statusline/statusline.sh`

---

## ccstatusline

npm package that renders the Claude Code status line in the terminal.

- **Invoked as:** `bunx -y ccstatusline@latest`
- **Configured in:** `~/.claude/settings.json` -> `statusLine`
- **Receives:** session JSON via stdin, `CCSTATUSLINE_CLAUDE_SESSION_ID` env var
- **Used by:** `claude-statusline/statusline.sh`

---

## Claude CLI

The Claude Code CLI itself. Used by hooks to invoke inner Claude sessions for summarization.

- **Install:** `npm install -g @anthropic-ai/claude-code`
- **Used by:** `hooks/update-recent-work.sh` (`claude -p --model haiku`)

---

## curl

HTTP client for making API requests. Pre-installed on macOS but listed here as a critical runtime dependency.

- **Install:** `brew install curl` (or use macOS system curl)
- **Used by:** `helpers/summarize.sh` (calls OpenAI API)

---

## gh (GitHub CLI)

GitHub's official CLI for managing issues, pull requests, and repository operations.

- **Install:** `brew install gh`
- **Used by:** `commands/git/issue.md`, `commands/pr/create.md`, `commands/pr/resolve.md`

---

## git

Distributed version control system. Used by nearly every command in this project.

- **Install:** `brew install git` (or use Xcode Command Line Tools)
- **Used by:** `commands/git/commit.md`, `commands/git/changelog.md`, `commands/git/version.md`, `commands/git/issue.md`, `commands/git/pull.md`, `commands/git/push.md`, `commands/pr/create.md`, `commands/pr/resolve.md`, `commands/worktree/create.md`, `commands/worktree/cleanup.md`, `commands/worktree/merge.md`, `commands/docs/update.md`, `skills/commit/SKILL.md`

---

## growlrrr (grrr) v1.2.0

Modern macOS notification CLI built on Apple's `UserNotifications` framework. Replaces the abandoned `terminal-notifier`.

- **Repo:** <https://github.com/moltenbits/growlrrr>
- **Used by:** `hooks/notify.sh`

### Install

```bash
brew tap moltenbits/tap
brew install growlrrr
```

Grant notification permission when prompted, or run manually:

```bash
grrr authorize
```

### Register Claude icon

Required once so notifications display the Claude icon:

```bash
grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png
```

Verify:

```bash
grrr apps list
```

### Usage (send subcommand)

```
growlrrr send [<options>] <message>
```

`send` is the default subcommand, so `grrr "Hello"` works.

| Flag | Description |
|---|---|
| `-t, --title` | Notification title |
| `-s, --subtitle` | Notification subtitle |
| `--sound <name>` | System sound name (`default`, `none`, `Hero`, `Glass`, etc.) |
| `--image <path>` | Image attachment (appears on right side) |
| `--appId <id>` | Custom app bundle (created via `grrr apps add`) |
| `--open <url>` | URL to open on click |
| `--execute <cmd>` | Shell command to run on click |
| `--identifier <id>` | Notification ID (for updates/removal) |
| `--threadId <id>` | Group related notifications together |
| `--wait` | Block until user interacts with notification |
| `--reactivate` | Reactivate terminal window on click |

### Other subcommands

| Command | Description |
|---|---|
| `grrr list` | List delivered notifications |
| `grrr clear` | Clear notifications |
| `grrr authorize` | Request notification permissions |
| `grrr apps add` | Add/update a custom notification app |
| `grrr apps list` | List custom apps |
| `grrr apps remove` | Remove a custom app |
| `grrr apps update` | Update all custom apps to latest executable |
| `grrr init` | Output shell hooks for auto-notifying long-running commands |

### Troubleshooting

**No notifications appearing:**

1. Check permissions: System Settings > Notifications > growlrrr (or `claude-code`) > Allow Notifications
2. Re-authorize: `grrr authorize`
3. Check Focus/DnD is off (growlrrr respects system DnD -- there is no override flag)

**Custom icon not showing:**

1. Verify app exists: `grrr apps list`
2. Re-register: `grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png`
3. Update bundles after brew upgrade: `grrr apps update`

---

## Homebrew

macOS package manager. Required to install everything else.

- **Install:** <https://brew.sh>
- **Used by:** all dependency installation below

---

## jq

JSON processor for parsing hook event data and session files.

- **Install:** `brew install jq`
- **Used by:** `hooks/notify.sh`, `hooks/load-recent-work.sh`, `hooks/update-recent-work.sh`, `helpers/summarize.sh`, `claude-statusline/statusline.sh`, `claude-statusline/last-user-input.sh`

---

## Linear MCP Server

MCP server providing access to Linear issue tracking. Enables commands to fetch issue details for branch naming and PR context.

- **Tool name:** `mcp__linear-server__get_issue`
- **Configured in:** Claude Code MCP settings
- **Used by:** `commands/pr/create.md`, `commands/worktree/create.md`

---

## Node.js (npm / npx)

JavaScript runtime providing `npm` (package manager) and `npx` (package executor). Required for several commands and npx-based tools.

- **Install:** `brew install node`
- **Used by:** `commands/git/version.md` (`npm version`), `commands/code/react-doctor.md` (`npx -y react-doctor@latest`), `skills/find-skills/SKILL.md` (`npx skills`)

---

## OpenAI API

Used for summarizing notification messages via GPT-4.1-nano. Requires an API key set as an environment variable.

- **Environment variable:** `CLAUDE_CODE_SUMMARIZER_API_KEY`
- **Endpoint:** `https://api.openai.com/v1/chat/completions`
- **Model:** `gpt-4.1-nano`
- **Used by:** `helpers/summarize.sh` (called by `hooks/notify.sh`)

Falls back to raw message truncation if the API key is missing.

---

## openspec

CLI tool for managing structured change workflows (proposals, designs, specs, tasks).

- **Install:** `npm install -g openspec`
- **Used by:** `commands/opsx/propose.md`, `commands/opsx/apply.md`, `commands/opsx/archive.md`, `commands/opsx/explore.md`, `skills/openspec-propose/SKILL.md`, `skills/openspec-apply-change/SKILL.md`, `skills/openspec-explore/SKILL.md`, `skills/openspec-archive-change/SKILL.md`

---

## pbcopy

macOS clipboard utility. Pre-installed on all Macs.

- **Install:** built-in (macOS system utility)
- **Used by:** `commands/git/changelog.md`, `commands/git/issue.md`, `commands/pr/create.md`

---

## pnpm

Fast, disk space efficient package manager. Referenced as an alternative to npm in documentation workflows.

- **Install:** `brew install pnpm`
- **Used by:** `commands/docs/update.md`

---

## react-doctor

npm package that scans React codebases for security, performance, correctness, and architecture issues. Auto-installs via npx.

- **Invoked as:** `npx -y react-doctor@latest . --verbose --diff`
- **Used by:** `commands/code/react-doctor.md`

---

## skills CLI

npm package for discovering and installing agent skills from the open skills ecosystem. Auto-installs via npx.

- **Invoked as:** `npx skills find [query]`, `npx skills add <package>`
- **Used by:** `skills/find-skills/SKILL.md`

---

## trash

Safe file deletion -- moves to Trash instead of permanent `rm`. Required by project conventions (see `CLAUDE.md`).

- **Install:** `brew install trash`
- **Used by:** all file deletion operations, `commands/worktree/cleanup.md`

| Command | Description |
|---|---|
| `trash file.txt` | Move file to Trash |
| `trash -r directory/` | Recursively trash a directory |
| `trash-list` | View trashed files |
| `trash-restore` | Recover deleted files |

---

## WezTerm

Terminal emulator. Notifications open WezTerm on click via `open -b`.

- **Bundle ID:** `com.github.wez.wezterm`
- **Install:** <https://wezfurlong.org/wezterm/installation>
- **Used by:** `hooks/notify.sh` (`--execute "open -b com.github.wez.wezterm"`)
