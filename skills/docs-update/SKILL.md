---
name: docs-update
description: Guided workflow for updating documentation based on code changes. Analyzes diffs, identifies affected docs, and applies updates with confirmation.
allowed-tools: Bash(git *), Bash(pnpm *), Read, Edit, Write, Glob, Grep
disable-model-invocation: true
---

# Documentation Updater

Guides you through updating documentation based on code changes on the active branch.

## Quick Start

1. **Analyze changes**: Run `git diff main...HEAD --stat` to see what files changed
2. **Identify affected docs**: Map changed source files to documentation paths
3. **Review each doc**: Walk through updates with user confirmation
4. **Validate**: Run linting to check formatting
5. **Commit**: Stage documentation changes

## Workflow: Analyze Code Changes

### Step 1: Get the diff

```bash
git diff main...HEAD --stat
git diff main...HEAD -- src/
```

### Step 2: Identify documentation-relevant changes

Look for changes that affect public APIs, configuration, components, or user-facing behavior.

### Step 3: Apply updates with confirmation

For each change:

1. Show the user what you plan to change
2. Wait for confirmation before editing
3. Apply the edit
4. Move to the next change

## Validation Checklist

Before committing documentation changes:

- [ ] Frontmatter has required fields
- [ ] Code blocks have proper attributes
- [ ] Related links point to valid paths
- [ ] Linting passes
