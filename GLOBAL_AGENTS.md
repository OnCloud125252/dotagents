# AGENTS.md

## Design Principles

- **Quality over cost:** Prioritize quality, simplicity, robustness, scalability, and maintainability over development cost.
- **No backward compatibility:** Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- **Simplest thing that works:** Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- **Grow in layers:** Start from the smallest version that works end to end. Add each new capability on top of a product that already works.
- **Never break what works:** Do not trade a working product for unfinished complexity.
- **Modular:** Keep components modular and concerns clearly separated.
- **Use libraries:** Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- **Check existing deps first:** Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- **Long term:** Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Code Style

- **Naming:** Descriptive names, reflecting purpose. Avoid abbreviations/single letters (except loop indices).
- **Comments:** Only explain "why", never "what" or "how". Code should explain itself.

## Workflow

- **Preparation:** Ask clarifying questions for ambiguous requirements. Always read existing code. Always create a todo list before starting.
- **Bug fixing:** Always reproduce the bug in an E2E setting first to ensure the real problem is solved.
- **High Standards:** Be obsessed with UI pixel perfection and engineering excellence (lint, tests). Fix obvious issues you spot alongside your work.
- **Validation:** Run linting and type checking before completion. After multiple file edits, re-read files to verify changes.
- **Entitlements:** Ask the user if an entitlement check is required when adding new features/services.
- **File deletion:** ALWAYS use `trash` instead of `rm`.

## Writing & Docs

- **Language:** Use **Traditional Chinese (zh-TW)** when Chinese is needed.
- **Markdown:** Put each full sentence on its own line; preserve structure but avoid line wrapping.
- **Attribution:** NEVER output "Generated with <agent>", "Co-Authored-By", or auto-add agent as co-author.
- **Agent doc updates:** Put doc updates on a dedicated branch (`update-agent-docs/$(date +%Y-%m-%d.%H-%M-%S)`) and open a PR. Don't bundle with features/fixes.
- **Agent doc content:** Record schemas and rules only. Use `<placeholders>`; NO real names, IDs, paths, or sample values as examples.
