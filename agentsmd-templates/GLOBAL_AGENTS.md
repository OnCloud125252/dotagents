# AGENTS.md

## Code Style Preferences

- Use 2 spaces for indentation (not tabs)
- Prefer async/await over promises
- Use meaningful variable names, avoid single letters except for loop indices
- Always use const/let, never use var in JavaScript/TypeScript
- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Be descriptive and avoid abbreviations
- Ensure names reflect purpose
- Avoid using barrel imports

## Testing Requirements

- Prefer TDD workflow (write tests first)
- Run linting and type checking before completing tasks

## Best Practices

- **Always use the LSP** (Language Server Protocol) for code intelligence — leverage go-to-definition, find-references, diagnostics, and symbol lookups instead of relying solely on text search
- When running scripts or commands that depend on the current git worktree, always verify the working directory first. Use `pwd` or check `.git` to confirm you're in the correct location, especially when working with feature branches or worktrees.
- **Prefer deterministic code over AI generation** — if a value (dates, IDs, checksums, etc.) can be computed programmatically, do that instead of letting an AI model generate or guess it

## Development Workflow

- always use `./.claude/worktrees` for creating and managing git worktrees for different branches or features. This keeps the main repository clean and organized while allowing for easy switching between contexts.
- **Always use askQuestionTools** for gathering information and clarifying requirements before starting any task
- Always create a todo list before starting any operation to track tasks and provide visibility
- Always read existing code before ANY process with more than one step
- Follow existing patterns and conventions in the codebase
- **Prefer modifying existing files** over creating new ones
- **Avoid running background tasks** like `bun run dev` - use foreground execution instead for better visibility and control
- **Spawn multiple subagents in parallel** when tasks are independent and can be done concurrently
- Never output "Generated with Claude Code" or "Co-Authored-By"
- **Always ask if entitlement is needed** — when implementing a new service or feature, ask the user whether an entitlement check is required before proceeding with the implementation

## Git Workflow

- **Always use merge as the default** for all git operations (e.g., `git pull`, branch integration) — do not rebase unless explicitly requested

## File Operations

- **ALWAYS use `trash` instead of `rm`** for file deletion

## Editing Guidelines

- After making multiple file edits, always verify the changes were applied correctly by reading the modified files before marking a task complete. Check for stale references or incomplete replacements.

## Language Preferences

- When Chinese is mentioned or needed, always use **Traditional Chinese (zh-TW)**
