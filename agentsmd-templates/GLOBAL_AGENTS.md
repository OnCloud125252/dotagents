# AGENTS.md

## General Guidelines

- **Never use the em dash "—".** Use plain dash "-" instead.
- **Never manually modify `CHANGELOG.md` files** or any files that are marked as auto-generated.
- **When writing or substantially editing long Markdown files,** put each full sentence on its own line. Preserve normal Markdown structure, but avoid wrapping multiple sentences onto one physical line.
- **When making technical decisions,** do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- **When doing bug fixes,** always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it. This makes sure you find the real problem so your fix will actually solve it.
- **When end-to-end testing a product,** be picky about the UI you see and be obsessed with pixel perfection. If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed alongside.
- **Apply that same high standard to engineering excellence:** lint, test failures, and test flakiness. If you see one, even if it is not caused by what you are working on right now, still get it fixed.

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
- **Code comments: only explain "why", never "what" or "how"** - code should explain itself. Do not write comments that narrate implementation steps, restate what the code already says, or add verbose step-by-step descriptions. Keep only comments that capture non-obvious rationale, constraints, or trade-offs the code cannot express on its own

## Best Practices

- **Always use the LSP** (Language Server Protocol) for code intelligence - leverage go-to-definition, find-references, diagnostics, and symbol lookups instead of relying solely on text search
- **Verify the worktree _and_ the checked-out branch** before any task that depends on git state. Run `pwd && git branch --show-current` as the first action - do **not** rely on the session-start git-status snapshot or on the worktree path implying a branch (a worktree at `.claude/worktrees/feat-xxx/` may actually be on `main` or a stale ref). If the branch isn't what the task expects, stop and confirm with the user before editing files. Re-check whenever you resume a long session or notice the snapshot diverging from reality.
- **Prefer deterministic code over AI generation** - if a value (dates, IDs, checksums, etc.) can be computed programmatically, do that instead of letting an AI model generate or guess it
- Run linting and type checking before completing tasks

## Development Workflow

- **Prefer using worktree** like `./.claude/worktrees` for creating and managing git worktrees for different branches or features. This keeps the main repository clean and organized while allowing for easy switching between contexts.
- **Always ask clarifying questions** before starting any task when requirements are ambiguous
- **Always create a todo list** before starting any operation to track tasks and provide visibility
- **Always read existing code** before ANY process with more than one step
- **Prefer modifying existing files** over creating new ones
- **Spawn multiple subagents in parallel** when tasks are independent and can be done concurrently
- **Always ask if entitlement is needed** - when implementing a new service or feature, ask the user whether an entitlement check is required before proceeding with the implementation
- **Never output "Generated with Claude Code" or "Co-Authored-By"** in any of your outputs. When writing commit messages, NEVER auto-add your agent name as co-author.

## Git Workflow

- **Always use merge as the default** for all git operations (e.g., `git pull`, branch integration) - do not rebase unless explicitly requested
- **Claude documentation updates** - whenever any Claude doc needs updating (`CLAUDE.md`, `.claude/rules/*`, `.claude/commands/*`, and other Claude config docs), put the change on its own dedicated branch and open a PR; never bundle it into an unrelated feature/fix PR. Name the branch `update-claude-docs/{time}`, where `{time}` comes from `date +%Y-%m-%d.%H-%M-%S`.

## Claude Docs Authoring

- **No examples in Claude docs** - when writing or updating any Claude config doc (`CLAUDE.md`, `.claude.local.md`, `.claude/rules/*`, `.claude/skills/*`, `.claude/commands/*`), record only the schema, rules, and conventions. Express naming patterns as angle-bracket placeholder templates; never embed real names, IDs, paths, or sample values as examples.

## Tracking & Progress Sync

- **Post milestone progress to the linked tracker.** When work reaches a milestone - a large or completed change, a resolved design decision, a status transition, a newly-found blocker, or an advanced acceptance criterion - record it on the work's tracker: a GitHub PR comment and/or the linked Linear issue. Routine intermediate edits, exploration, reading, and small fixes are not milestones; do not post them.
- **When milestone progress exists but no tracker is linked** (no open PR, no linked issue), **ask the user** whether to create one before posting. Never auto-create a PR or issue, and never silently drop the progress.

## File Operations

- **ALWAYS use `trash` instead of `rm`** for file deletion

## Editing Guidelines

- After making multiple file edits, always verify the changes were applied correctly by reading the modified files before marking a task complete. Check for stale references or incomplete replacements.

## Language Preferences

- When Chinese is mentioned or needed, always use **Traditional Chinese (zh-TW)**

## Git Commit Conventions

- Follow Conventional Commits format (feat, fix, docs, style, refactor, test, chore)
- Keep commit messages under 72 characters
- Write commit messages in imperative mood
