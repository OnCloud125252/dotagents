# Project Dependencies

All external tools required by this environment. Install everything with the [quick setup](#quick-setup) or follow individual sections below.

## Quick Setup

```bash
# Package manager (prerequisite)
# Install Homebrew if not present: https://brew.sh

# Core CLI tools
brew install git gh jq curl trash bun node pnpm direnv ripgrep python

# Status line
bun install -g ccstatusline

# Notifications
brew tap moltenbits/tap
brew install growlrrr
grrr authorize
grrr apps add --appId claude-code --appIcon ~/.agents/hooks/claude-icon.png

# Environment variables
# Set CLAUDE_CODE_SUMMARIZER_API_KEY to an OpenAI API key for notification summaries
# Write a Discord webhook URL to skills/discord-notify/scripts/webhook.url for /discord-notify
```

Docker is needed only by the `image-diet` skill. Install it separately from <https://docs.docker.com/get-docker/>.

---

## Bun

JavaScript runtime and package manager. Also installs the `ccstatusline` binary used by the status line.

- **Install:** `brew install bun`
- **Used by:** `claude-statusline/statusline.sh`, `skills/git-commit/SKILL.md`, `skills/pr-review/SKILL.md`, `skills/image-diet/SKILL.md`, `skills/image-diet/scripts/detect-project.mjs`

---

## ccstatusline

npm package that renders the Claude Code status line in the terminal.

- **Install:** `bun install -g ccstatusline`
- **Invoked as:** `~/.bun/bin/ccstatusline`
- **Configured in:** `~/.config/ccstatusline/settings.json`
- **Receives:** session JSON via stdin, `CCSTATUSLINE_CLAUDE_SESSION_ID` env var
- **Used by:** `claude-statusline/statusline.sh`

The scripts `claude-statusline/last-user-input.sh`, `claude-statusline/peer-id.sh`, `claude-statusline/short-pwd.sh`, and `claude-statusline/thinking-effort.sh` run as `custom-command` widgets inside ccstatusline.

---

## claude-peers broker

Local HTTP service that tracks peer agent sessions. The status line asks it which peer ID belongs to the current session.

- **Endpoint:** `http://127.0.0.1:$CLAUDE_PEERS_PORT/list-peers` (port defaults to `7899`)
- **Environment variable:** `CLAUDE_PEERS_PORT` (optional)
- **Used by:** `claude-statusline/peer-id.sh`

The script prints nothing and exits 0 when the broker does not answer, so the status line still works without it.

---

## curl

HTTP client for API requests.

- **Install:** `brew install curl` (or use macOS system curl)
- **Used by:** `helpers/summarize.sh` (calls the OpenAI API), `claude-statusline/peer-id.sh` (calls the claude-peers broker)

---

## direnv

Directory-specific environment variables. Activates `.envrc` when entering a new worktree.

- **Install:** `brew install direnv`
- **Used by:** `skills/worktree-create/SKILL.md` (optional — silently skipped if not installed)

---

## Discord webhook

External service that receives task notifications in a Discord forum channel.

- **Setup:** create a forum-channel webhook in Discord, then save the URL to `skills/discord-notify/scripts/webhook.url`
- **Used by:** `skills/discord-notify/scripts/discord_notify.py`, `skills/discord-notify/SKILL.md`

The webhook URL is a secret. `skills/discord-notify/scripts/.gitignore` keeps it out of git.

---

## Docker

Container engine. The image-diet skill builds images and reads their layer sizes to measure each slimming stage.

- **Install:** <https://docs.docker.com/get-docker/>
- **Used by:** `skills/image-diet/scripts/measure-image.sh`, `skills/image-diet/references/capability-probes.md`

---

## gh (GitHub CLI)

GitHub's official CLI for issues, pull requests, and repository operations.

- **Install:** `brew install gh`
- **Used by:** `skills/pr-create/SKILL.md`, `skills/pr-resolve/SKILL.md`, `skills/pr-review/SKILL.md`

---

## git

Distributed version control system. Used by nearly every skill in this project.

- **Install:** `brew install git` (or use Xcode Command Line Tools)
- **Used by:** `skills/api-doc/SKILL.md`, `skills/commit-message-style/SKILL.md`, `skills/find-simplifications/SKILL.md`, `skills/git-commit/SKILL.md`, `skills/git-push/SKILL.md`, `skills/handoff/SKILL.md`, `skills/pr-create/SKILL.md`, `skills/pr-resolve/SKILL.md`, `skills/pr-review/SKILL.md`, `skills/worktree-cleanup/SKILL.md`, `skills/worktree-create/SKILL.md`, `skills/worktree-merge/SKILL.md`, `skills/worktree-sync/SKILL.md`, `hooks/suggest-worktree.sh`, `.agents/skills/publish/SKILL.md`

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
grrr apps add --appId claude-code --appIcon ~/.agents/hooks/claude-icon.png
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
2. Re-register: `grrr apps add --appId claude-code --appIcon ~/.agents/hooks/claude-icon.png`
3. Update bundles after brew upgrade: `grrr apps update`

---

## Homebrew

macOS package manager. Required to install most other dependencies.

- **Install:** <https://brew.sh>
- **Used by:** all dependency installation below

---

## Huly MCP Server

MCP server providing access to Huly issue tracking. It exposes a proxy, so tools are reached through `search_tools`, `get_tool_schema`, and `invoke_tool`.

- **Configured in:** agent MCP settings
- **Used by:** `skills/huly-mcp-guide/SKILL.md`, `skills/api-doc/SKILL.md`, `skills/pr-create/SKILL.md`, `skills/worktree-create/SKILL.md`

---

## jq

JSON processor for parsing hook event data and session files.

- **Install:** `brew install jq`
- **Used by:** `claude-statusline/last-user-input.sh`, `claude-statusline/peer-id.sh`, `claude-statusline/statusline.sh`, `claude-statusline/thinking-effort.sh`, `helpers/summarize.sh`, `hooks/notify.sh`, `hooks/suggest-worktree.sh`

---

## kitty

Terminal emulator. Notifications focus the exact kitty window that started the session, and fall back to raising the app.

- **Bundle ID:** `net.kovidgoyal.kitty`
- **Install:** <https://sw.kovidgoyal.net/kitty/binary/>
- **Used by:** `hooks/notify.sh` (`kitten @ focus-window`, `open -b net.kovidgoyal.kitty`)

Precise window focus needs kitty remote control turned on. Without it the hook still raises the app.

---

## Linear MCP Server

MCP server providing access to Linear issue tracking. Skills use it to fetch issue details for branch naming, PR context, and issue status updates. Several named instances can be configured at once, one per workspace.

- **Tool prefix:** `mcp__Linear_<workspace>__*`
- **Configured in:** agent MCP settings
- **Used by:** `skills/linear-mcp-guide/SKILL.md`, `skills/api-doc/SKILL.md`, `skills/pr-create/SKILL.md`, `skills/worktree-create/SKILL.md`

---

## Node.js (npm / npx)

JavaScript runtime providing `npm` (package manager) and `npx` (package executor). Also runs the brainstorming server and the image-diet analysis scripts.

- **Install:** `brew install node`
- **Used by:** `skills/code-react-doctor/SKILL.md` (`npx -y react-doctor@latest`), `skills/brainstorming/scripts/start-server.sh`, `skills/brainstorming/scripts/server.cjs`, `skills/image-diet/scripts/bundle-roots.mjs`, `skills/image-diet/scripts/detect-project.mjs`, `skills/image-diet/scripts/prune-runtime-modules.mjs`

---

## OpenAI API

Used for summarizing notification messages via `gpt-4.1-nano`. Requires an API key set as an environment variable.

- **Environment variable:** `CLAUDE_CODE_SUMMARIZER_API_KEY`
- **Endpoint:** `https://api.openai.com/v1/chat/completions`
- **Models:** `gpt-4.1-nano` (notifications)
- **Used by:** `helpers/summarize.sh` (called by `hooks/notify.sh`)

Falls back to raw message truncation if the API key is missing.

---

## pbcopy / pbpaste

macOS clipboard utilities. Pre-installed on all Macs. `pbcopy` writes to the clipboard; `pbpaste` reads from it.

- **Install:** built-in (macOS system utilities)
- **Used by:** `skills/pbcopy/SKILL.md`

---

## pnpm

Fast, disk space efficient package manager. Used to run Biome and project test scripts in pnpm-based repos.

- **Install:** `brew install pnpm`
- **Used by:** `skills/pr-review/SKILL.md`, `skills/image-diet/scripts/detect-project.mjs`

---

## Python 3

Scripting runtime. The discord-notify script uses only the standard library, so no extra packages are needed.

- **Install:** `brew install python` (or use the macOS system python3)
- **Used by:** `skills/discord-notify/scripts/discord_notify.py`, `skills/pr-review/SKILL.md` (`python -m pytest` in Python repos)

---

## react-doctor

npm package that scans React codebases for security, performance, correctness, and architecture issues. Auto-installs via npx.

- **Invoked as:** `npx -y react-doctor@latest . --verbose --diff`
- **Used by:** `skills/code-react-doctor/SKILL.md`

---

## ripgrep (rg)

Fast recursive code search. Used to prove or reject simplification candidates by finding every call site of a symbol.

- **Install:** `brew install ripgrep`
- **Used by:** `skills/find-simplifications/SKILL.md`

---

## trash

Safe file deletion -- moves to Trash instead of permanent `rm`. Required by project conventions (see `AGENTS.md`).

- **Install:** `brew install trash`
- **Used by:** all file deletion operations, `skills/worktree-cleanup/SKILL.md`, `skills/realistic-scenario-runbook/SKILL.md`, `.agents/skills/publish/SKILL.md`

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
