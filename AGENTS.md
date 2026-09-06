# dotagents

Source repo for Claude Code customizations (skills, hooks, rules, store catalog).

## Live vs. installed — know which one you're editing

- **Live symlinks (edits take effect immediately):** `~/CLAUDE.md` → `agentsmd-templates/GLOBAL_AGENTS.md`, and `~/.claude/rules` → `rules/`
- **Installed copies (edits here do NOT go live):** `~/.claude/skills`, `~/.claude/hooks` are real directories installed via the store flow (`store-prompt.md`). After changing `skills/` or `hooks/`, the live copies must be re-installed/synced separately.

## Layout

- `claude-statusline/` — ccstatusline `custom-command` scripts; **live** (referenced by absolute path in `~/.config/ccstatusline/settings.json`), so edits apply on next render with no install step. Gotchas: `rules/ccstatusline.md`
- `skills/` — agent skills, one flat directory each (`git-commit/`, `pr-review/`). Skills converted from legacy slash commands carry `disable-model-invocation: true` (user-invoked only, never auto-triggered); `SKILL.md` frontmatter carries a `generatedBy` skill-creator version
- `rules/` — path-scoped rules; YAML frontmatter `paths:` globs control activation, no frontmatter = always loaded. Keep the "Path-scoped rules" table in `agentsmd-templates/GLOBAL_AGENTS.md` in sync when adding or re-scoping a rule
- `store/catalog.json` — machine-readable catalog consumed by the `store-prompt.md` installer
- `gemini-commands/` — Gemini CLI equivalents, converted from `skills/` via `/convert-to-gemini-command` (regeneration from the new skills layout is pending)
- `agentsmd-templates/` — `GLOBAL_AGENTS.md` is the LIVE global config; the other files are reusable snippets, not live

## Workflow

- After adding/renaming a skill, run `/publish` — it regenerates `store/catalog.json`, `dependency.md`, and the README, then commits and pushes
- New external tool requirements go in `dependency.md` (`/update-dependencies` scans for them)
- Rule files: one gotcha per bullet, earned from real incidents — not generic advice
