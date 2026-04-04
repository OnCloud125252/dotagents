# Slash Commands

> Reusable prompt-driven commands for Claude Code and Gemini CLI.

## Overview

Commands live in two directories, one per assistant:

| Directory | Format | Invocation |
|---|---|---|
| `commands/` | Markdown (`.md`) | `/command-name` in Claude Code |
| `gemini-commands/` | TOML (`.toml`) | `/command-name` in Gemini CLI |

Both sets share the same logic. Gemini commands use `{{args}}` for arguments
instead of `$ARGUMENTS`.

## Quick reference

| Command | Description |
|---|---|
| `/auto-resolve` | Run a command and loop diagnose-fix-execute until exit code 0 |
| `/search` | Web search with synthesized summary and citations |

### `git.*` — Version control

| Command | Description |
|---|---|
| `/git.commit` | Group recent changes into logical Conventional Commits |
| `/git.issue` | Create a GitHub issue via `gh`, auto-detect labels, copy URL |
| `/git.changelog` | Generate a user-facing changelog from git history |
| `/git.version` | Analyze git changes and create a new version using `npm version` |

### `pr.*` — Pull requests

| Command | Description |
|---|---|
| `/pr.create` | Push current branch and create a GitHub pull request |
| `/pr.resolve` | Fetch unresolved PR review threads and fix them |

### `docs.*` — Documentation

| Command | Description |
|---|---|
| `/docs.agentsmd` | Create or refactor AGENTS.md with progressive disclosure |
| `/docs.update` | Guided workflow for updating docs based on code changes |

### `code.*` — Code quality

| Command | Description |
|---|---|
| `/code.simplify` | Ruthlessly refactor code for maximum simplicity |
| `/code.react-doctor` | Scan React codebase for issues, output 0-100 score |

### Gemini-only commands

| Command | Description |
|---|---|
| `/fix-agentsmd` | Standalone AGENTS.md refactor (5-step process) |
| `/fully-optimize-code` | Full project optimization pipeline using code-simplifier |

## Speckit workflow

The `speckit.*` commands form a specification-driven development pipeline.
Run them in order:

```
specify → clarify → plan → tasks → analyze → implement
                                ↘ checklist
                                ↘ taskstoissues
```

| Command | Step | Description |
|---|---|---|
| `/speckit.constitution` | 0 | Create or update the project constitution |
| `/speckit.specify` | 1 | Generate `spec.md` from a natural language description |
| `/speckit.clarify` | 2 | Ask up to 5 clarification questions, write answers into spec |
| `/speckit.checklist` | 3 | Generate a requirements quality checklist |
| `/speckit.plan` | 4 | Produce `research.md`, `data-model.md`, API contracts, `quickstart.md` |
| `/speckit.tasks` | 5 | Generate dependency-ordered `tasks.md` from design artifacts |
| `/speckit.analyze` | 6 | Cross-artifact consistency and quality analysis (read-only) |
| `/speckit.implement` | 7 | Execute tasks phase by phase, marking `[X]` on completion |
| `/speckit.taskstoissues` | — | Convert tasks to GitHub Issues via `gh` |

### Speckit artifacts

All artifacts are written to a feature directory (typically `.specify/`):

```
.specify/
├── memory/
│   └── constitution.md
├── spec.md
├── research.md
├── data-model.md
├── contracts/
├── quickstart.md
├── tasks.md
└── checklists/
    └── requirements.md
```

## Command details

### `/auto-resolve`

```
/auto-resolve <command>
```

Runs the given shell command and enters a recursive **Diagnose → Fix →
Execute** loop until the command exits with code 0.

### `/git.commit`

Scans staged and unstaged git changes, groups them into logical commits, and
creates each with a Conventional Commits message. Supports types: `feat`,
`fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`.

No AI attribution is added to commit messages.

### `/git.issue`

```
/git.issue <title> [--body "description"] [--label bug|feature|docs] [--assignee user]
```

Creates a GitHub issue via `gh`. Auto-detects labels from title keywords
(e.g., "bug" → `bug`, "feature" → `enhancement`). Copies the issue URL to
the clipboard.

### `/git.changelog`

```
/git.changelog [from_commit] [language] [--show-commits]
```

Generates a Markdown changelog grouped by feature area. Defaults to the
latest tag or `HEAD~20`. Supports English, Traditional Chinese, Simplified
Chinese, Japanese, and Korean. Skips `chore`, `refactor`, `test`, `style`,
`ci`, and `build` commits.

### `/git.version`

```
/git.version [--dry-run]
```

Analyzes git commits since the last tag to determine the appropriate semantic
version bump, then runs `npm version`.

### `/pr.create`

Push current branch and create a GitHub pull request with smart defaults.

### `/pr.resolve`

Fetch unresolved PR review threads, fix the issues, reply with commit SHA,
resolve threads via GraphQL, and post a summary comment.

### `/docs.agentsmd`

Create or refactor AGENTS.md with progressive disclosure principles.

### `/docs.update`

Guided workflow for updating documentation based on code changes. Analyzes
diffs, identifies affected docs, and applies updates with confirmation.

### `/code.simplify`

```
/code.simplify [target]
```

Aggressively refactors the target file, directory, or component for maximum
simplicity. Eliminates code smells, over-engineering, and duplication while
preserving all functionality and public APIs. Defaults to recently modified
files.

### `/code.react-doctor`

Scans your React codebase for security, performance, correctness, and
architecture issues. Outputs a 0-100 score with actionable diagnostics.

### `/search`

```
/search [query]
```

Performs a web search and returns a synthesized summary with inline
`[1], [2]` citations and source links.
