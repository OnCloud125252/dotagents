---
name: Cleanup Worktree
description: Remove a git worktree and optionally delete its branch. Lists worktrees if no argument given.
argument-hint: "[worktree-name-or-path]"
allowed-tools: Bash(git *), AskUserQuestion
---

# Cleanup Git Worktree

Remove a git worktree and its local branch when done with a feature.

## Input Parsing

| Input | Action |
|---|---|
| No argument | List all worktrees, ask which to remove |
| Directory name (e.g., `sei-381-blacklist-management`) | Match against worktree directories |
| Full path | Use directly |
| Branch name | Find worktree associated with that branch |

## Steps

### 1. List Current Worktrees

Always start by listing:

```bash
git worktree list
```

**If no argument was given:** Display the list and ask the user which worktree(s) to clean up. Do NOT proceed without user selection.

**If argument was given:** Match it against the list. If no match, report and stop.

### 2. Confirm with User

Before removing, show:
- Worktree path
- Branch name
- Whether the branch has been merged into main/master

Ask for confirmation before proceeding.

### 3. Check for Uncommitted Changes

```bash
cd <worktree-path> && git status --short
```

**If dirty:** Warn the user about uncommitted changes and ask whether to proceed or abort.

### 4. Remove Worktree

```bash
git worktree remove <worktree-path>
```

If it fails due to uncommitted changes and user confirmed they want to proceed:

```bash
git worktree remove --force <worktree-path>
```

### 5. Optionally Delete Branch

Check if the branch has been merged:

```bash
git branch --merged main | grep "<branch-name>"
```

- **If merged:** Offer to delete the local branch: `git branch -d <branch-name>`
- **If NOT merged:** Warn that the branch is unmerged. Only delete with `git branch -D` if the user explicitly confirms.

### 6. Report

```
Removed worktree: <path>
Deleted branch: <branch-name> (or "Branch kept: <branch-name>")
Remaining worktrees: <count>
```

## Safety

- **ALWAYS confirm** before removing a worktree
- **ALWAYS warn** about uncommitted changes
- **ALWAYS warn** about unmerged branches before deletion
- **NEVER** use `--force` without explicit user approval
- Use `trash` instead of `rm` if manual cleanup of leftover directories is needed
