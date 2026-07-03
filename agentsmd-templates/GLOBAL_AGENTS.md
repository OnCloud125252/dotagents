# AGENTS.md

## General Guidelines

- **Use plain dash "-"**; never use em dash ("—").
- **No auto-generated edits:** Never manually modify `CHANGELOG.md` or auto-generated files.
- **Markdown:** Put each full sentence on its own line; preserve structure but avoid line wrapping.
- **Technical decisions:** Prioritize quality, simplicity, robustness, scalability, and maintainability over development cost.
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
- **Tools:** Use LSP (go-to-definition, find-references, diagnostics) instead of just text search.
- **Validation:** Run linting and type checking before completion. After multiple file edits, re-read files to verify changes.

## Development Workflow

- **Git State:** Run `pwd && git branch --show-current` first. Don't rely on initial snapshots. Stop and ask if branch is unexpected.
- **Worktrees:** Prefer `.claude/worktrees` for branches to keep the main repo clean.
- **Git Operations:** Default to merge (`git pull`); no rebase unless requested.
- **Preparation:** Ask clarifying questions for ambiguous requirements. Always read existing code. Always create a todo list before starting.
- **Execution:** Prefer modifying existing files over creating new ones. Spawn parallel subagents for independent tasks.
- **Entitlements:** Ask the user if an entitlement check is required when adding new features/services.
- **Attribution:** NEVER output "Generated with Claude Code", "Co-Authored-By", or auto-add agent as co-author in commit messages.

## Tracking & Progress Sync

- **Milestones:** Post progress on large changes, blockers, or decisions to the linked PR/Linear issue. Skip routine minor edits.
- **No tracker?** Ask the user before posting milestone progress. Never auto-create PRs/issues or drop progress silently.

## Agent Docs Authoring

- **Updates:** Put doc updates on a dedicated branch (`update-claude-docs/$(date +%Y-%m-%d.%H-%M-%S)`) and open a PR. Don't bundle with features/fixes.
- **Content:** Record schemas and rules only. Use `<placeholders>`; NO real names, IDs, paths, or sample values as examples.
