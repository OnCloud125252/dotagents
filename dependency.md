# Project Dependencies

All external tools required by this environment. Install everything with the [quick setup](#quick-setup) or follow individual sections below.

## Quick Setup

```bash
# Package manager (prerequisite)
# Install Homebrew if not present: https://brew.sh

# Core CLI tools
brew install jq trash ripgrep bun

# Notifications
brew tap moltenbits/tap
brew install growlrrr
grrr authorize
grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png

# Status line
bunx -y ccstatusline@latest
```

---

## Homebrew

macOS package manager. Required to install everything else.

- **Install:** <https://brew.sh>
- **Used by:** all dependency installation below

---

## jq

JSON processor for parsing hook event data from stdin.

- **Install:** `brew install jq`
- **Used by:** `hooks/notify.sh`

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
3. Check Focus/DnD is off (growlrrr respects system DnD — there is no override flag)

**Custom icon not showing:**

1. Verify app exists: `grrr apps list`
2. Re-register: `grrr apps add --appId claude-code --appIcon ~/.claude/hooks/claude-icon.png`
3. Update bundles after brew upgrade: `grrr apps update`

---

## Bun

JavaScript runtime. Provides `bunx` for running npm packages without global install.

- **Install:** `brew install bun`
- **Used by:** `~/.claude/settings.json` (status line)

---

## ccstatusline

npm package that renders the Claude Code status line in the terminal.

- **Invoked as:** `bunx -y ccstatusline@latest`
- **Configured in:** `~/.claude/settings.json` → `statusLine`
- **Receives:** session JSON via stdin, `CCSTATUSLINE_CLAUDE_SESSION_ID` env var

---

## trash

Safe file deletion — moves to Trash instead of permanent `rm`. Required by project conventions (see `CLAUDE.md`).

- **Install:** `brew install trash`
- **Used by:** all file deletion operations

| Command | Description |
|---|---|
| `trash file.txt` | Move file to Trash |
| `trash -r directory/` | Recursively trash a directory |
| `trash-list` | View trashed files |
| `trash-restore` | Recover deleted files |

---

## ripgrep (rg)

Fast recursive search. Preferred over `grep` per project conventions.

- **Install:** `brew install ripgrep`
- **Used by:** code search workflows

---

## WezTerm

Terminal emulator. Notifications open WezTerm on click via `open -b`.

- **Bundle ID:** `com.github.wez.wezterm`
- **Install:** <https://wezfurlong.org/wezterm/installation>
- **Used by:** `hooks/notify.sh` (`--execute "open -b com.github.wez.wezterm"`)
