---
paths:
  - "**/.claude/recent-work/linear-sync-queue.md"
---

# Linear issue ⇄ progress-comment sync

The `update-recent-work.sh` Stop hook posts milestone-level progress to the Linear
issue linked to the current branch. When it flags a turn as significant (large/complete
change, resolved decision, new blocker, or an acceptance criterion advanced) **and** the
branch name carries a Linear issue ID, it **appends** an entry to:

```
<worktree>/.claude/recent-work/linear-sync-queue.md
```

You do **not** re-judge significance per edit — your job is to **drain the queue**.

## Resolving the issue ID (from the branch, not a file)

There is no `.linear.md` mirror to read — the issue ID comes from the branch name.
Run `git branch --show-current`, take the first `<letters>-<digits>` segment, and
uppercase it (e.g. `<issue-id>-<slug>` → `<ISSUE-ID>`). The queue's header comment
also records the ID the hook resolved; prefer that if present, otherwise derive it from
the branch.

## Draining the queue

Whenever you see a non-empty `linear-sync-queue.md` — at session start (the
`check-sync-queue` hook nudges you) or any time you notice it — flush it before the
session ends:

1. **Claim it (avoid the async-hook race).** `mv` the queue to a temp name first
   (`linear-sync-queue.flushing.md`) and read *that*. The Stop hook keeps appending to
   a fresh `linear-sync-queue.md`, so renaming first means no entry is lost to a
   concurrent append.
2. **Resolve the issue ID** from the queue header or the branch (above). If no ID can
   be derived, the branch is not Linear-linked — see below.
3. **Post ONE merged comment.** Combine all entries' progress notes into a single
   concise comment and post with `mcp__Linear*__save_comment` (the issue ID + body). Do
   not post one comment per entry — that spams the issue's activity feed.
4. **Clear:** delete the temp queue file. If the Linear write **failed**, rename the
   temp file back to `linear-sync-queue.md` and tell the user — never drop unsynced
   progress.

## Status transitions are not this rule's job

Status (`In Progress` / `In Review` / `Done`) is set at lifecycle moments by the skills
that own them — `worktree:create` marks `In Progress` when work starts, `pr:create`
marks `In Review` when the PR opens — and/or by Linear's native GitHub integration
(branch/PR lifecycle). Do **not** guess status transitions from arbitrary turns here;
this rule posts progress **comments** only.

## No linked issue for the queued progress

If the queue has entries but the branch carries no Linear issue ID, do **not** silently
drop the notes and do **not** invent an issue. Ask the user which issue to post to (or
whether to discard); if they decline, tell them the queued notes will be discarded, then
delete the temp file.

## Notes

- `save_comment` is **outward-facing** — teammates see it. The queue means the
  significance gate already passed, so you may flush without re-confirming. But if a
  queued note looks wrong (e.g. claims completion while CI is red), pause and ask the
  user first.
- A worktree can be linked to **both** a Linear issue and a PR; the hook queues the same
  progress note to each. Drain `linear-sync-queue.md` (this rule) and
  `github-sync-queue.md` (github-pr-sync rule) independently.
