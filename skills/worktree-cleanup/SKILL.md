---
name: worktree-cleanup
description: Remove a git worktree and optionally delete its branch. Lists worktrees if no argument given.
argument-hint: "[worktree-name-or-path]"
disable-model-invocation: true
user-invocable: true
---

# Cleanup Git Worktree

Remove a git worktree and its local branch when done with a feature.

## Input Parsing

| Input | Action |
|---|---|
| No argument | List all worktrees, ask which to remove |
| Directory name (e.g., `<issue-id>-<keywords>`) | Match against worktree directories |
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

### 2. Assess Branch Status (per worktree)

**IMPORTANT:** Do NOT use `git branch --merged main` — it is unreliable. A branch at the same commit as main (new/empty) trivially passes the merge check, giving false positives.

**IMPORTANT:** Always compare against `origin/main`, NOT the local `main` ref. The local `main` branch may be stale if the user hasn't pulled recently (common in worktree-based workflows where the main checkout is rarely touched). Using a stale local `main` inflates the "commits ahead" count — any commits from `origin/main` that were merged into the feature branch will appear as "ahead" of the outdated local `main`, causing a merged branch to look active.

Instead, gather the following for each worktree branch:

```bash
# Fetch latest remote state first
git fetch origin --prune

# For each branch, check:
# 1. Commits ahead of origin/main (unique commits on this branch)
#    MUST use origin/main, not local main — local main may be stale
git rev-list --count origin/main..<branch-name>

# 2. Remote branch existence
git ls-remote --heads origin <branch-name> | wc -l

# 3. Upstream tracking
git rev-parse --abbrev-ref <branch-name>@{upstream}

# 4. Working tree status
cd <worktree-path> && git status --short
```

Classify each branch into one of these categories:

| Category | Commits Ahead of origin/main | Remote Exists | Description |
|----------|------------------------------|---------------|-------------|
| **Merged** | 0 | No | Work was squash/merge-merged, remote branch deleted. Safe to remove. |
| **Active** | >0 | Yes | Has unmerged commits and remote branch. In-progress work. |
| **New/Empty** | 0 | No, tracking main | Freshly created branch with no work done yet. Safe to remove. |
| **Stale** | 0 | No | No unique commits but may have uncommitted local changes. Check dirty status. |

Present a summary table to the user showing: worktree path, branch name, status (clean/dirty), category, and unique commit count.

### 3. Check Git-Ignored Files

Before removing, check if the worktree contains git-ignored files that may hold local state (e.g., `.env`, `.env.*`, `tmp/`). Run:

```bash
cd <worktree-path> && git status --ignored --short
```

Also compare common ignored files against the main worktree:

```bash
# Example check for .env files
diff <main-worktree>/.env <worktree-path>/.env
```

If ignored files exist only in the worktree or differ from main, warn the user and ask whether to copy them back to the main worktree before cleanup. Common candidates: `.env`, `.env.local`, `.env.*.local`, `tmp/dev.log`, `tmp/collector.log`.

### 4. Confirm with User

Before removing, show:

- Worktree path
- Branch name
- Category (Merged / Active / New/Empty / Stale)
- Dirty status (uncommitted changes)
- Git-ignored files status (any to preserve)

**If dirty:** Warn the user about uncommitted changes and ask whether to proceed or abort.

**If Active (unmerged commits):** Warn that the branch has unmerged work.

**If git-ignored files differ:** Offer to copy them back to the main worktree first.

Ask for confirmation before proceeding.

### 5. Remove Worktree

```bash
git worktree remove <worktree-path>
```

If it fails due to uncommitted changes and user confirmed they want to proceed:

```bash
git worktree remove --force <worktree-path>
```

### 6. Delete Branch

**Note:** `git branch -d` compares against the local `main`, which may be stale. For branches confirmed merged via `origin/main` comparison in Step 2, use `git branch -D` directly — the `-d` safe check will give a false "not fully merged" error when local `main` is behind `origin/main`.

Based on category:

- **Merged / New/Empty:** Delete with `git branch -D <branch-name>` (safe — already confirmed merged against `origin/main` in Step 2)
- **Active / Stale with uncommitted changes:** Warn that the branch has unmerged work. Only delete with `git branch -D` if the user explicitly confirms.

### 7. Report

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
