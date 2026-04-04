# Development Workflow

## Before Starting

- **Create a todo list** before any multi-step operation for progress tracking
- **Read existing code** before any multi-step process
- **Prefer modifying existing files** over creating new ones
- **Spawn subagents in parallel** when tasks are independent

## During Work

- **Prefer TDD** — write tests before implementation
- **Avoid background tasks** (e.g. `bun run dev`) — use foreground execution for visibility
- Run tests after changes if test scripts exist
- Run linting and type checking before completing tasks
- **Verify working directory** (`pwd`) before running scripts that depend on the git worktree
- **Use `./.claude/worktrees`** for all git worktree creation and management

## After Edits

- **Verify changes** by reading modified files before marking a task complete — check for stale references or incomplete replacements

## Tool Preferences

- Use `ripgrep` (`rg`) instead of `grep`
- Prefer Glob and Grep tools over bash `find`/`grep` commands
- Always use absolute paths when working with files
- **Use LSP** for code intelligence — go-to-definition, find-references, diagnostics over text search

## Git

- Never add "Generated with Claude Code" or "Co-Authored-By" to commits
