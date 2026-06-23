---
paths:
  - "**/.claude/recent-work/github-sync-queue.md"
---

# GitHub PR ⇄ process-comment sync

The `update-recent-work.sh` Stop hook posts milestone-level progress to the open PR
for the current branch. When it flags a turn as significant (large/complete change,
resolved decision, status transition, new blocker, or an acceptance criterion
advanced) **and** the branch has an open PR, it **appends** an entry to:

```
<worktree>/.claude/recent-work/github-sync-queue.md
```

You do **not** re-judge significance per edit — your job is to **drain the queue**.

## Draining the queue

Whenever you see a non-empty `github-sync-queue.md` — at session start (the
`check-sync-queue` hook nudges you) or any time you notice it — flush it before the
session ends:

1. **Claim it (avoid the async-hook race).** `mv` the queue to a temp name first
   (`github-sync-queue.flushing.md`) and read *that*. The Stop hook keeps appending
   to a fresh `github-sync-queue.md`, so renaming first means no entry is lost to a
   concurrent append.
2. **Resolve the PR number.** Read it from the queue's header comment (`PR #<n>`), or
   `gh pr view --json number,state` for the current branch. Confirm it is still
   `OPEN`.
3. **Post ONE merged comment.** Combine all entries' notes into a single concise
   comment and post with `gh pr comment <n> --body "<merged note>"`. Never post one
   comment per entry — that spams the PR thread.
4. **Clear:** delete the temp queue file. If `gh pr comment` **failed**, rename the
   temp file back to `github-sync-queue.md` and tell the user — never drop unsynced
   progress.

## No open PR for the queued progress

If the queue has entries but there is no open PR (it was merged/closed, or the branch
never had one), do **not** silently drop the notes and do **not** auto-create a PR.
Ask the user whether to open one (`/pr:create`); if they decline, tell them the queued
notes will be discarded, then delete the temp file.

## Notes

- `gh pr comment` is **outward-facing** — collaborators see it. The queue means the
  significance gate already passed, so you may flush without re-confirming. But if a
  queued note looks wrong (e.g. claims completion while CI is red), pause and ask the
  user first.
- A worktree can be linked to **both** a Linear issue and a PR; the hook queues the
  same progress note to each. Drain `linear-sync-queue.md` (linear-sync rule) and
  `github-sync-queue.md` independently.
