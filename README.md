# .agents

Shared configuration, hooks, and skills for AI coding assistants (Claude Code, Gemini CLI, Codex).

## Structure

```
.agents/
├── hooks/                    # Event-driven shell scripts
│   ├── notify.sh             # macOS notifications via growlrrr (grrr)
│   └── claude-icon.png       # Notification icon for Claude
├── claude-statusline/        # Terminal status line scripts
│   ├── statusline.sh         # Main status line runner (bunx ccstatusline)
│   ├── short-pwd.sh          # Shortened working directory display
│   └── last-user-input.sh    # Extract last user message from session
├── commands/                 # Claude Code slash commands (.md)
├── gemini-commands/          # Gemini CLI commands (.toml)
├── agentsmd-templates/       # AGENTS.md generation templates
├── skills/                   # Installed agent skills
├── AGENTS.md                 # Coding conventions and workflow rules
└── dependency.md             # External tool setup and reference
```

## Setup

See [dependency.md](dependency.md) for install instructions and tool reference.

## Hooks

`hooks/notify.sh` sends macOS notifications on Claude Code events:

- **Stop** — "Operation Finished" with Hero sound, shows last assistant message
- **Notification** — "Input Needed" with Glass sound, shows the notification message

Configured in `~/.claude/settings.json` under `hooks`. Clicking a notification opens WezTerm.

## Status Line

`claude-statusline/` powers the Claude Code terminal status bar via [ccstatusline](https://www.npmjs.com/package/ccstatusline). Configured in `~/.claude/settings.json` under `statusLine`.
