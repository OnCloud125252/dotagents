# AGENTS.md

## General Guidelines

- **Use plain dash "-"**; never use em dash ("—").
- **No auto-generated edits:** Never manually modify `CHANGELOG.md` or auto-generated files.
- **Markdown:** Put each full sentence on its own line; preserve structure but avoid line wrapping.
- **Technical decisions:** Prioritize quality, simplicity, robustness, scalability, and maintainability over development cost.
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- **Bug fixing:** Always reproduce the bug in an E2E setting first to ensure the real problem is solved.
- **High Standards:** Be obsessed with UI pixel perfection and engineering excellence (lint, tests). Fix obvious issues you spot alongside your work.
- **File deletion:** ALWAYS use `trash` instead of `rm`.
- **Language:** Use **Traditional Chinese (zh-TW)** when Chinese is needed.

## Code Style & Best Practices

- **Formatting:** 2 spaces for indentation (no tabs).
- **Naming:** Descriptive names, reflecting purpose. Avoid abbreviations/single letters (except loop indices). JavaScript/TypeScript: camelCase variables/functions, PascalCase classes/components, SCREAMING_SNAKE_CASE constants.
- **Variables:** Always use `const/let`, never `var`.
- **Promises:** Prefer `async/await`.
- **Imports:** Avoid barrel imports.
- **Comments:** Only explain "why", never "what" or "how". Code should explain itself.
- **Deterministic > AI:** Compute values programmatically (dates, IDs, etc.) instead of AI generation.
- **Validation:** Run linting and type checking before completion. After multiple file edits, re-read files to verify changes.

## Development Workflow

- **Git State:** Run `pwd && git branch --show-current` first. Don't rely on initial snapshots. Stop and ask if branch is unexpected.
- **Worktrees (default):** Do all code changes in a `.claude/worktrees` worktree by default to keep the main repo clean. Create the worktree automatically without asking; treat it as the standard workflow, not a per-task decision. Skip only when the user explicitly opts out, the directory is not a git repo, or the task genuinely cannot run in a worktree (e.g., an operation that must act on the primary checkout). When in doubt, use a worktree.
- **Git Operations:** Default to merge (`git pull`); no rebase unless requested.
- **Autonomy:** For low-complexity, low-risk work, decide and act on your own; this includes opening PRs and merging, up to and including the default branch (`main`/`master`). Get my approval first for high-complexity work, or for anything genuinely risky or hard to reverse (destructive/irreversible operations, secrets/credentials, production-affecting changes). When you can't tell which tier a task is, treat it as high and ask.
- **Preparation:** Ask clarifying questions for ambiguous requirements. Always read existing code. Always create a todo list before starting.
- **Execution:** Prefer modifying existing files over creating new ones. Spawn parallel subagents for independent tasks.
- **Entitlements:** Ask the user if an entitlement check is required when adding new features/services.
- **Attribution:** NEVER output "Generated with Claude Code", "Co-Authored-By", or auto-add agent as co-author in commit messages.

## Tracking & Progress Sync

- **Milestones:** Post progress on large changes, blockers, or decisions to the linked PR/Linear issue. Skip routine minor edits.
- **No tracker?** Ask the user before posting milestone progress; never drop it silently. Don't spin up a PR/issue solely to host progress notes (creating a PR for actual work follows **Autonomy** above).

## Agent Docs Authoring

- **Updates:** Put doc updates on a dedicated branch (`update-claude-docs/$(date +%Y-%m-%d.%H-%M-%S)`) and open a PR. Don't bundle with features/fixes.
- **Content:** Record schemas and rules only. Use `<placeholders>`; NO real names, IDs, paths, or sample values as examples.
