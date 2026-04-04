# AGENTS.md Templates

> Reusable template sections for generating `AGENTS.md` files tailored to
> different project types.

## Overview

The `agentsmd-templates/` directory contains modular sections that the
`/docs.agentsmd` command uses as building blocks. Each template
provides conventions for a specific concern (coding standards, git workflow,
platform, etc.) and can be combined to assemble a full `AGENTS.md`.

## Templates

| Template | Section heading | Description |
|---|---|---|
| `coding-standards.md` | Code Style | 2-space indent, `async/await`, no barrel imports, naming conventions |
| `git-commit-conventions.md` | Git Commits | Conventional Commits format, 72-char subjects, imperative mood |
| `git-workflow.md` | Git Workflow | Expanded version of commit conventions as a standalone section |
| `ios.md` | iOS | Build with `xcbeautify`, use XcodeGen (`project.yml`), skip `.xcodeproj` |
| `nodejs.md` | Node.js | Mandate `bun` as runtime/package manager; allow npm/yarn only if lock files exist |
| `workflow.md` | Workflow | Run tests/lint after changes, use `ripgrep`, absolute paths, `trash` over `rm` |

## Usage

Templates are consumed by the `/docs.agentsmd` command
(defined in `commands/docs.agentsmd.md`). The command:

1. Detects the project type (Node.js, iOS, etc.)
2. Selects relevant templates
3. Combines them into an `AGENTS.md` following progressive disclosure —
   essentials at the top, details linked as separate files

You can also reference templates manually when bootstrapping a new project:

```bash
cat agentsmd-templates/coding-standards.md agentsmd-templates/workflow.md > AGENTS.md
```

## Template conventions

- Each template is a self-contained Markdown section (starting with `#`)
- Templates use generic placeholders that the command fills in
- Platform templates (`ios.md`, `nodejs.md`) include tool-specific install instructions
- `workflow.md` enforces the project-wide rule: **always use `trash` instead of `rm`**
