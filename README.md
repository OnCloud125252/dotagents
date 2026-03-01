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
├── docs/                     # Documentation
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

## Commands

Slash commands for Claude Code (`commands/`) and Gemini CLI (`gemini-commands/`), including the full speckit specification-driven development workflow.

See [docs/commands.md](docs/commands.md) for the complete reference.

## Skills

Nine installed agent skills covering code simplification, documentation, frontend design, React diagnostics, and more.

See [docs/skills.md](docs/skills.md) for the full list.

## Documentation

| Page | Description |
|---|---|
| [docs/hooks.md](docs/hooks.md) | Notification hooks — events, configuration, troubleshooting |
| [docs/statusline.md](docs/statusline.md) | Status line setup, available data, custom scripts |
| [docs/commands.md](docs/commands.md) | All slash commands and the speckit workflow |
| [docs/skills.md](docs/skills.md) | Installed agent skills overview |
| [docs/agentsmd-templates.md](docs/agentsmd-templates.md) | AGENTS.md generation templates |
| [docs/code-style.md](docs/code-style.md) | Code style conventions |
| [docs/workflow.md](docs/workflow.md) | Development workflow rules |
| [dependency.md](dependency.md) | External tool install guide |
