# .agents

Shared hooks, status line scripts, slash commands, and skills for AI coding assistants.

## Essentials

- **Always use `trash` instead of `rm`** for file deletion (recoverable via `trash-restore`)
- When Chinese is needed, always use **Traditional Chinese (zh-TW)**

## Conventions

- [Code Style](docs/code-style.md) — indentation, naming, JS/TS rules
- [Workflow](docs/workflow.md) — task tracking, testing, tool preferences
- [Dependencies](dependency.md) — external tool setup and reference

## Key Files

| File | Purpose |
|---|---|
| `hooks/notify.sh` | macOS notifications using growlrrr (`grrr`) |
| `claude-statusline/statusline.sh` | Terminal status line via `bunx ccstatusline` |
| `dependency.md` | External tool install guide and reference |
