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
| `/create-commits` | Group recent changes into logical Conventional Commits |
| `/create-issue` | Create a GitHub issue via `gh`, auto-detect labels, copy URL |
| `/create-or-update-agentsmd` | Create or refactor AGENTS.md with progressive disclosure |
| `/generate-changelog` | Generate a user-facing changelog from git history |
| `/search` | Web search with synthesized summary and citations |
| `/simplify` | Ruthlessly refactor code for maximum simplicity |

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

### `/create-commits`

Scans staged and unstaged git changes, groups them into logical commits, and
creates each with a Conventional Commits message. Supports types: `feat`,
`fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`.

No AI attribution is added to commit messages.

### `/create-issue`

```
/create-issue <title> [--body "description"] [--label bug|feature|docs] [--assignee user]
```

Creates a GitHub issue via `gh`. Auto-detects labels from title keywords
(e.g., "bug" → `bug`, "feature" → `enhancement`). Copies the issue URL to
the clipboard.

### `/generate-changelog`

```
/generate-changelog [from_commit] [language] [--show-commits]
```

Generates a Markdown changelog grouped by feature area. Defaults to the
latest tag or `HEAD~20`. Supports English, Traditional Chinese, Simplified
Chinese, Japanese, and Korean. Skips `chore`, `refactor`, `test`, `style`,
`ci`, and `build` commits.

### `/search`

```
/search [query]
```

Performs a web search and returns a synthesized summary with inline
`[1], [2]` citations and source links.

### `/simplify`

```
/simplify [target]
```

Aggressively refactors the target file, directory, or component for maximum
simplicity. Eliminates code smells, over-engineering, and duplication while
preserving all functionality and public APIs. Defaults to recently modified
files.
