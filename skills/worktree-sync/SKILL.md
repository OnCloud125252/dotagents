---
name: worktree-sync
description: Sync a worktree branch with main by merging origin/main into it. Use when the worktree branch has fallen behind main.
argument-hint: "[worktree-name-or-path-or-branch]"
disable-model-invocation: true
user-invocable: true
---

# Sync Worktree with Main

Merge the latest `origin/main` into a worktree branch to bring it up-to-date. This is the inverse of `/worktree-merge` — instead of merging the worktree into main, it merges main into the worktree.

**Announce at start:** "Syncing worktree with main..."

## Input Parsing

| Input | Action |
|---|---|
| No argument | Use current directory as the worktree |
| Directory name (e.g., `<issue-id>-<keywords>`) | Match against known worktrees |
| Full path | Use directly |
| Branch name | Find worktree associated with that branch |

## Steps

### 1. Resolve Worktree Path

List all worktrees to find the target:

```bash
git worktree list --porcelain
```

**If no argument given:** Use the current directory (`pwd`). Verify it appears in the worktree list — if not, report and stop.

**If argument given:** Match against:

1. Full path
2. Worktree directory name (last path segment)
3. Branch name (`branch` field in porcelain output)

If no match, report and stop.

Store the resolved path as `<worktree-path>` and its branch as `<branch-name>`.

### 2. Guard: Reject main/master

```bash
git -C <worktree-path> branch --show-current
```

If `<branch-name>` is `main` or `master`, stop immediately:

> Cannot sync main into itself. Switch to a feature branch worktree.

### 3. Check for Uncommitted Changes

```bash
git -C <worktree-path> status --short
```

If the worktree is dirty (has uncommitted changes), warn the user and stop:

> The worktree has uncommitted changes. Commit or stash them before syncing.

### 4. Fetch Latest main

```bash
git fetch origin main
```

If fetch fails (e.g., no remote), warn the user but ask whether to proceed with the local `origin/main` ref.

### 5. Check Divergence

Run in parallel:

```bash
# Commits from origin/main not yet in this branch (incoming)
git log --oneline <branch-name>..origin/main

# Commits from this branch not in origin/main (ahead)
git log --oneline origin/main..<branch-name>
```

**If 0 incoming commits:** Report "Already up-to-date. No changes to sync." and stop.

**If incoming commits exist:** Display a summary table:

| Detail | Value |
|---|---|
| **Worktree** | `<worktree-path>` |
| **Branch** | `<branch-name>` |
| **Incoming commits** | `<count>` from `origin/main` |
| **Branch ahead by** | `<count>` commits not yet in main |

Show the incoming commit list (up to 10; summarize if more):

```
Incoming from origin/main:
  <sha> <message>
  <sha> <message>
  ...
```

### 6. Confirm

Ask for confirmation before merging:

> Merge origin/main into `<branch-name>`? (Y/n)

Do NOT proceed without user confirmation.

### 7. Merge

```bash
git -C <worktree-path> merge origin/main --no-edit
```

Always use merge — never rebase. The `--no-edit` flag accepts the default merge commit message.

### 8. Handle Conflicts

If the merge produces conflicts:

1. Show which files have conflicts:

   ```bash
   git -C <worktree-path> diff --name-only --diff-filter=U
   ```

2. Abort immediately to restore clean state:

   ```bash
   git -C <worktree-path> merge --abort
   ```

3. Report:

   > Merge aborted. The following files have conflicts that must be resolved manually:
   >
   > - `<file1>`
   > - `<file2>`
   >
   > Resolve the conflicts, then re-run `/worktree-sync`.

4. Stop — do NOT attempt automatic conflict resolution.

### 9. Verify and Report

After a successful merge:

```bash
git -C <worktree-path> log --oneline -5
```

Report:

```
Synced: origin/main → <branch-name>
Commits merged: <N>
Worktree: <worktree-path>
```

## Safety

- **ALWAYS confirm** before merging
- **NEVER proceed** with a dirty worktree
- **NEVER operate** on main or master
- **ABORT cleanly** on conflicts — leave the worktree in its original state
- **Use merge only** — never rebase (per project convention)
- **NEVER auto-resolve** conflicts

## Do NOT

- Push to remote
- Modify any source files
- Delete or remove any worktrees
- Run tests or install dependencies
