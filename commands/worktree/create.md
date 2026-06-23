---
name: Create Worktree
description: Create a git worktree from a branch name or Linear issue. Fetches branch name from Linear MCP when given an issue ID/URL.
argument-hint: <branch-name | Linear issue ID | Linear issue URL>
allowed-tools: Bash(git *), Bash(mkdir *), Bash(date *), Bash(basename *), Bash(cp *), Bash(direnv *), Bash(command *), Read, mcp__Linear*__get_issue, mcp__Linear*__save_issue
model: claude-haiku-4-5
---

# Worktree from Branch or Linear Issue

Create a git worktree with a new branch. Accepts either a direct branch name or a Linear issue identifier.

**Announce at start:** "Setting up worktree..."

## Input Parsing

The argument can be one of:

| Input Format | Example | Action |
|---|---|---|
| Linear URL | `https://linear.app/<workspace>/issue/<ISSUE-ID>/...` | Extract issue ID (`<ISSUE-ID>`), fetch from Linear |
| Linear issue ID | `<ISSUE-ID>` | Fetch from Linear |
| Branch name | `feat/my-feature` | Use directly |

### Detecting Linear issue IDs

A Linear issue ID matches the pattern: 2-5 uppercase letters, a hyphen, then digits.

Check both the raw argument and any ID extracted from a URL.

## Steps

### 1. Resolve Branch Name

**If the input is a Linear issue (ID or URL):**

```
Use mcp__Linear*__get_issue with the issue ID to fetch:
- title (for display)
- gitBranchName (for the branch)
- status, assignee, labels (for summary)
```

Use the `gitBranchName` field from the response as the branch name.

**If the input is a plain branch name:**

Use it directly. No Linear lookup needed.

### 2. Derive Worktree Directory Name

Create a short directory name from the branch:

- If branch contains an issue ID, use: `<issue-id>-<first-few-keywords>`
- Otherwise, use the last path segment of the branch name, truncated to ~40 chars

Examples:

- `<prefix>/<issue-id>-<full-description>` → `<issue-id>-<short-keywords>`
- `<type>/<feature-name>` → `<feature-name>`

### 3. Determine Worktree Base Directory

Priority order:

1. Check CLAUDE.md for a worktree directory preference (e.g., `.claude/worktrees`)
2. Check if `.claude/worktrees`, `.worktrees`, or `worktrees` exists
3. Default to `.claude/worktrees`

Ensure the directory exists (`mkdir -p`).

### 4. Check if Branch Already Exists

```bash
git branch --list "<branch-name>"
git worktree list
```

- If the branch and worktree already exist, report the existing path and stop.
- If the branch exists but no worktree, create worktree from existing branch:
  `git worktree add <path> <branch-name>` (no `-b` flag).
- If neither exists, create both:
  `git worktree add <path> -b <branch-name>`

### 5. Verify

```bash
cd <worktree-path> && git branch --show-current && pwd
```

### 6. Copy Local Environment Files

Copy gitignored local configuration files from the **main repo root** (not from `pwd` — resolve via `git worktree list | head -1 | awk '{print $1}'`) into the new worktree. This prevents developers from having to manually re-create their local environment in every worktree.

```bash
MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}')
WORKTREE_PATH="<worktree-path>"
```

**Files to copy (if they exist in the main repo):**

| Source | Destination | Notes |
|---|---|---|
| `.vscode/settings.json` | `.vscode/settings.json` | Create `.vscode/` dir if needed |
| `.claude/settings.local.json` | `.claude/settings.local.json` | Claude Code local overrides |
| `.env` | `.env` | Environment variables |

For each file, check if it exists in `$MAIN_REPO`. If it does and does NOT exist in the worktree, copy it. Do not overwrite existing files.

**direnv:** If `.envrc` exists in the worktree, run `direnv allow` so the environment activates automatically. If `direnv` is not installed, skip silently.

```bash
if [ -f "$WORKTREE_PATH/.envrc" ] && command -v direnv &>/dev/null; then
  cd "$WORKTREE_PATH" && direnv allow
fi
```

Report which files were copied and whether direnv was allowed, as a brief note in the summary.

### 7. Mark Linear Issue In Progress

**Only if the input was a Linear issue (ID or URL):**

Use `mcp__Linear*__save_issue` to update the issue status:

```
id: <issue-id>       (the uppercased Linear issue ID)
state: "In Progress"
```

If the status update fails, log a warning but do not block — the worktree is already created.

### 8. Report Summary

**If from Linear issue, display:**

| Detail | Value |
|---|---|
| **Issue** | `[<ID>](<url>)` — `<title>` |
| **Status** | `<status>` |
| **Branch** | `<branch-name>` |
| **Worktree** | `<relative-path>` |

**If from branch name, display:**

| Detail | Value |
|---|---|
| **Branch** | `<branch-name>` |
| **Worktree** | `<relative-path>` |

## Error Handling

- **Linear issue not found:** Report the error, ask user to provide a branch name instead.
- **Branch name conflict:** If `-b` fails because the branch exists, retry without `-b`.
- **Worktree path already in use:** Append a number suffix (e.g., `-2`).

## Do NOT

- Run `npm install`, `pnpm install`, or any dependency installation
- Run tests
- Change the working directory of the outer session
