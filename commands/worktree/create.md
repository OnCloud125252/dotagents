---
name: Create Worktree
description: Create a git worktree from a branch name or Linear issue. Fetches branch name from Linear MCP when given an issue ID/URL.
argument-hint: <branch-name | Linear issue ID | Linear issue URL>
allowed-tools: Bash(git *), Bash(mkdir *), Bash(date *), Bash(basename *), Write, Read, mcp__Linear*__get_issue, mcp__Linear*__save_issue
model: claude-haiku-4-5
---

# Worktree from Branch or Linear Issue

Create a git worktree with a new branch. Accepts either a direct branch name or a Linear issue identifier.

**Announce at start:** "Setting up worktree..."

## Input Parsing

The argument can be one of:

| Input Format | Example | Action |
|---|---|---|
| Linear URL | `https://linear.app/zeabur/issue/SEI-381/...` | Extract issue ID (`SEI-381`), fetch from Linear |
| Linear issue ID | `SEI-381` | Fetch from Linear |
| Branch name | `feat/my-feature` | Use directly |

### Detecting Linear issue IDs

A Linear issue ID matches the pattern: 2-5 uppercase letters, a hyphen, then digits (e.g., `SEI-381`, `PLA-1004`).

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

- If branch contains an issue ID (e.g., `sei-381`), use: `<issue-id>-<first-few-keywords>`
- Otherwise, use the last path segment of the branch name, truncated to ~40 chars

Examples:

- `oncloud/sei-381-implement-blacklist-management-in-admin-panel` → `sei-381-blacklist-management`
- `feat/add-user-search` → `add-user-search`

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

### 6. Hydrate `.linear.md` (Linear issues only)

**Only if the input was a Linear issue (ID or URL) and step 1 succeeded:**

Using the issue data already fetched in step 1, write a `.linear.md` file to the worktree root. Read the template from `.claude/templates/linear.md` in the repo (relative to the main worktree or the new worktree). Replace the template placeholders:

| Placeholder | Value |
|---|---|
| `{{ISSUE_ID}}` | The Linear issue identifier (e.g., `PLA-1360`) |
| `{{ISSUE_URL}}` | The issue's URL (e.g., `https://linear.app/zeabur/issue/PLA-1360`) |
| `{{ISSUE_TITLE}}` | The issue's title |
| `{{ISSUE_STATUS}}` | The issue's current status name (e.g., `In Progress`) |
| `{{WORKTREE_NAME}}` | The worktree directory name (e.g., `pla-1360-integrate-hooks`) |
| `{{LAST_SYNCED_UTC}}` | Current UTC time in ISO-8601 format (e.g., `2026-04-28T22:11:00Z`) |
| `{{ISSUE_DESCRIPTION}}` | The issue's description (markdown) |
| `{{ACCEPTANCE_CRITERIA}}` | Extract from description if available, otherwise `(none specified)` |

Write the rendered file to `<worktree-path>/.linear.md` using the Write tool.

**If the template file is not found**, construct the `.linear.md` inline using the same frontmatter keys and markdown sections.

**If MCP failed in step 1** (issue fetch error), skip this step silently — log a warning that `.linear.md` was not created and the user can re-run sync later. Do not block worktree creation.

### 7. Mark Linear Issue In Progress

**Only if the input was a Linear issue (ID or URL):**

Use `mcp__Linear*__save_issue` to update the issue status:

```
id: <issue-id>       (e.g., "SEI-381")
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
