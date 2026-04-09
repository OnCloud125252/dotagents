---
name: Publish Store Update
description: Update store catalog, dependencies, README, then commit and push
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(cat:*), Bash(which:*), Bash(command:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(diff:*), Skill
model: claude-sonnet-4-6
---

Synchronize all derived files with the current state of commands, skills, hooks, helpers, and statusline scripts, then commit and push.

## Phase 1: Scan Current State

### 1a. Discover commands

Use Glob to find all `commands/**/*.md` files recursively. For each file:

1. Read the YAML frontmatter
2. Extract: `name`, `description`, `allowed-tools`, `model`, `argument-hint`
3. Scan the body for:
   - Skill references: patterns like "Invoke the /X skill", "/X skill using the Skill tool", or Skill tool invocations → record as `requires_skills`
   - External CLI tools: `openspec`, `npx`, `gh`, `npm`, `pnpm`, `grrr`, `bunx`, `trash`, `jq`, `bun`, `curl` → record as `requires_tools`
   - MCP server tools: `mcp__*` references → record as `optional_tools` with key `mcp:<server-name>`
4. Derive the command key from the path relative to `commands/` without `.md` extension (e.g., `commands/git/commit.md` → `git/commit`)

### 1b. Discover skills

Use Glob to find all `skills/*/SKILL.md` files. **Exclude** `skills/.system/`. For each file:

1. Read the YAML frontmatter
2. Extract: `name`, `description`, `version`, `allowed-tools`, `license`, `compatibility`, `metadata`
3. Scan the body for:
   - Trigger condition summary (usually described in the first section)
   - External tool references → record as `requires_tools`
4. Check if the skill directory has subdirectories (e.g., `rules/`, `references/`) → record as `has_subdirs`
5. The skill key is the directory name (e.g., `skills/commit/` → `commit`)

### 1c. Discover infrastructure scripts

Scan **all** shell scripts and source files in these directories for external tool dependencies:

- `hooks/*.sh`
- `helpers/*.sh`
- `claude-statusline/*.sh`

For each file, detect:

- Direct command invocations (e.g., `jq`, `grrr`, `curl`, `bunx`, `claude`, `open`, `tput`)
- `brew install` / `brew tap` references
- `bunx -y <package>` / `npx <package>` patterns
- `curl` / `fetch` calls to external APIs → record the API as a dependency
- Environment variable reads (`$VAR_NAME`) that are API keys or runtime config
- `open -b <bundle-id>` patterns → record the application as a dependency

Record each tool with its source file path. These tools feed into the `external_tools` object in Phase 2 but do NOT create catalog `commands` or `skills` entries.

## Phase 2: Update `store/catalog.json`

1. Read the current `store/catalog.json`
2. Rebuild the `commands` and `skills` objects from the scan results in Phase 1. Each command must include a `category` field — derive it from the command key prefix (e.g., `git/commit` → `"git"`, `pr/create` → `"pr"`). Root-level commands without a prefix (e.g., `search`, `auto-resolve`) get category `"standalone"`.
3. Update the `categories` array:
   - Collect all unique `category` values from the rebuilt commands.
   - Preserve existing category entries (keep their `label` and `note` fields).
   - Add new categories for any newly discovered prefixes with `"label"` set to the capitalized prefix and `"note": null`.
   - Remove categories that no longer have any commands.
   - Maintain the existing order — append new categories at the end.
4. Preserve the existing `bundles` object — but validate that all referenced command/skill keys still exist. If a bundle references a deleted item, **remove it from the bundle**. If a bundle references no items, **remove the bundle**.
5. Check if new commands or skills were added that are not in any bundle — report them at the end so the user can decide whether to add them to bundles later.
6. Rebuild the `external_tools` object by collecting all unique tool names from `requires_tools` across all commands, skills, **and infrastructure scripts** (hooks, helpers, statusline from Phase 1c). For each tool, preserve the existing `check`, `install`, and `description` fields if the tool was already in the catalog. For new tools, use sensible defaults:
   - `check`: `command -v <tool>`
   - `install`: `brew install <tool>` (or `npm install -g <tool>` for npm packages)
   - `description`: infer from context
7. Preserve the `optional_integrations` object — update `used_by` lists based on current `optional_tools` references.
8. Write the updated `store/catalog.json`

### Validation

After writing, verify the JSON is valid by reading it back. Report what changed:

- Commands added/removed
- Skills added/removed
- External tools added/removed
- Bundle items pruned (if any)

## Phase 3: Update `dependency.md`

Invoke the `/update-dependencies` command using the Skill tool.

## Phase 4: Update `README.md`

Read the current `README.md` and check if it needs updates based on the scan results:

### Sections to check

1. **Overview counts** — The bullet list says "X slash commands" and "Y skills". Update the numbers if they changed.
2. **Commands table** — The namespace table listing commands per namespace. If a command was added/removed/moved, update the table.
3. **Skills table** — The skill-trigger table. If a skill was added/removed, update the table.
4. **Directory tree** — If a new top-level directory was added (unlikely), update the tree. Also ensure `store/` is listed.

### Rules

- Only edit sections that actually need changes. Do NOT rewrite the entire file.
- Preserve all other sections (Hooks, Status Line, FAQs, Installation, etc.) untouched.
- Match the existing markdown style exactly (table alignment, link format, etc.).
- If nothing changed, skip this phase entirely and report "README.md is up to date."

## Phase 5: Commit

Invoke the `/git:commit` command using the Skill tool.

## Phase 6: Push

Invoke the `/git:push` command using the Skill tool.

## Summary

After all phases complete, display a summary:

```
========================================
  Publish Complete
========================================
  Catalog:      X commands, Y skills, Z bundles
  Dependencies: (updated / no changes)
  README:       (updated / no changes)
  Commit:       <short SHA> <message>
  Push:         <branch> → origin
========================================
```

If new items were found that aren't in any bundle, append:

```
  New items not in any bundle:
    - <command or skill key>
  Consider adding them to bundles in store/catalog.json
```
