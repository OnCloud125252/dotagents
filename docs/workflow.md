# Development Workflow

## Before Starting

- **Create a todo list** before any multi-step operation for progress tracking
- **Spawn subagents in parallel** when tasks are independent

## During Work

- **Avoid background tasks** (e.g. `bun run dev`) — use foreground execution for visibility
- Run tests after changes if test scripts exist
- Run linting and type checking before completing tasks

## Tool Preferences

- Use `ripgrep` (`rg`) instead of `grep`
- Prefer Glob and Grep tools over bash `find`/`grep` commands
- Always use absolute paths when working with files
