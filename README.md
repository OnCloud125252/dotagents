# .agents

Shared configuration, hooks, and skills for AI coding assistants (Claude Code, Gemini CLI, Codex).

## Structure

```
.agents/
├── hooks/                    # Event-driven shell scripts
│   ├── notify.sh             # macOS notifications via growlrrr (grrr)
│   ├── load-recent-work.sh   # SessionStart hook — load prior work context
│   ├── update-recent-work.sh # Stop hook — summarize and persist session work
│   └── claude-icon.png       # Notification icon for Claude
├── helpers/                  # Shared helper scripts
│   └── summarize.sh          # Summarize messages via OpenAI gpt-4.1-nano
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
├── GLOBAL_AGENTS.md          # Global coding standards (shared across projects)
└── dependency.md             # External tool setup and reference
```

## Setup

See [dependency.md](dependency.md) for install instructions and tool reference.

## Hooks

`hooks/notify.sh` sends macOS notifications on Claude Code events:

- **Stop** — "Operation Finished" with Hero sound, shows summarized assistant message
- **Notification** — "Input Needed" with Glass sound, shows the notification message

Messages are summarized via `helpers/summarize.sh` (OpenAI gpt-4.1-nano) before display.

`hooks/load-recent-work.sh` and `hooks/update-recent-work.sh` provide **session context persistence**:

- **SessionStart** — loads `.claude/RECENT_WORK.md` so new sessions pick up where you left off
- **Stop** — summarizes the conversation and updates `.claude/RECENT_WORK.md`

Configured in `~/.claude/settings.json` under `hooks`. Clicking a notification opens WezTerm.

## Status Line

`claude-statusline/` powers the Claude Code terminal status bar via [ccstatusline](https://www.npmjs.com/package/ccstatusline). Configured in `~/.claude/settings.json` under `statusLine`.

## Commands

Slash commands for Claude Code (`commands/`) and Gemini CLI (`gemini-commands/`), organized by namespace:

- `git.*` — version control (commit, issue, changelog, version)
- `pr.*` — pull requests (create, resolve)
- `docs.*` — documentation (agentsmd, update)
- `code.*` — code quality (simplify, react-doctor)
- `worktree.*` — git worktree management (create, cleanup)
- General — auto-resolve, search, organize-dir

See [docs/commands.md](docs/commands.md) for the complete reference.

## Skills

Nine installed agent skills covering output styling, commit workflows, documentation, dashboards, i18n, React best practices, and more.

See [docs/skills.md](docs/skills.md) for the full list.

## Documentation

| Page | Description |
|---|---|
| [docs/hooks.md](docs/hooks.md) | Notification hooks — events, configuration, troubleshooting |
| [docs/statusline.md](docs/statusline.md) | Status line setup, available data, custom scripts |
| [docs/commands.md](docs/commands.md) | All slash commands — git, PR, docs, code, worktree |
| [docs/skills.md](docs/skills.md) | Installed agent skills overview |
| [docs/agentsmd-templates.md](docs/agentsmd-templates.md) | AGENTS.md generation templates |
| [docs/code-style.md](docs/code-style.md) | Code style conventions |
| [docs/workflow.md](docs/workflow.md) | Development workflow rules |
| [dependency.md](dependency.md) | External tool install guide |
