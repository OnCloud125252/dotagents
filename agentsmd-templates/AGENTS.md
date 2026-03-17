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

## Development Workflow

- **Always use askQuestionTools** for gathering information and clarifying requirements before starting any task
- Always create a todo list before starting any operation to track tasks and provide visibility
- Always read existing code before ANY process with more than one step
- Follow existing patterns and conventions in the codebase
- **Prefer modifying existing files** over creating new ones
- **Avoid running background tasks** like `bun run dev` - use foreground execution instead for better visibility and control
- **Spawn multiple subagents in parallel** when tasks are independent and can be done concurrently

## File Operations

- **ALWAYS use `trash` instead of `rm`** for file deletion

## Editing Guidelines

- After making multiple file edits, always verify the changes were applied correctly by reading the modified files before marking a task complete. Check for stale references or incomplete replacements.

## Language Preferences

- When Chinese is mentioned or needed, always use **Traditional Chinese (zh-TW)**
