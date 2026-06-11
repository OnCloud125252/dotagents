---
paths:
  - "**/.linear.md"
  - "**/.claude/recent-work/linear-sync-queue.md"
---

# `.linear.md` ⇄ Linear online sync

A worktree linked to a Linear issue has a `.linear.md` at its root — frontmatter
(`issue`, `url`, `title`, `status`, `worktree`, `last_synced`) plus body
(description, acceptance criteria, linked artifacts). Treat `.linear.md` as the
**offline** mirror and the Linear issue as the **online** source of truth. Keep
them in sync as work progresses.

## Significance is decided by the hook, not by you per-edit

The `update-recent-work.sh` Stop hook asks a model to judge each turn. When it
flags milestone-level progress (large/complete change, resolved decision, status
transition, new blocker, or an acceptance criterion advanced), it **appends** an
entry to the sync queue:

```
<worktree>/.claude/recent-work/linear-sync-queue.md
```

You do **not** re-judge significance per edit — your job is to **drain the queue**.

## Draining the queue (flush online + offline)

The SessionStart hook nudges you when the queue is non-empty. Whenever you see a
non-empty `linear-sync-queue.md` — at session start, or any time you notice it —
flush it before the session ends:

1. **Claim it (avoid the async-hook race).** `mv` the queue to a temp name first
   (e.g. `linear-sync-queue.flushing.md`) and read *that*. The Stop hook keeps
   appending to a fresh `linear-sync-queue.md`, so renaming first means no entry
   is lost to a concurrent append.
2. **Push online via the Linear MCP**, reading `issue` from `.linear.md` frontmatter:
   - **Status:** if any entry carries `status: <Name>` (≠ `(unchanged)`), call
     `mcp__Linear_Lazco__save_issue` with `id` = the issue ID and `state` = that
     status. Collapse multiple status entries to the **last** one — one update.
   - **Comment:** merge the entries' progress notes into a **single** concise
     Linear comment via `mcp__Linear_Lazco__save_comment`. Do not post one comment
     per line — that spams the issue's activity feed.
3. **Update `.linear.md` offline:** set frontmatter `status:` to the new status,
   set `last_synced:` to the current UTC ISO-8601 — compute it
   (`date -u +%Y-%m-%dT%H:%M:%SZ`), never guess — and tick any acceptance-criteria
   checkboxes the work completed.
4. **Clear:** delete the temp queue file. If a Linear write **failed**, rename the
   temp file back to `linear-sync-queue.md` and tell the user — never drop unsynced
   progress.

## Editing `.linear.md` directly

- You are the **sole writer** of `.linear.md`; the Stop hook only ever appends to
  the queue. So editing it needs no locking.
- `last_synced` is the inbound-drift anchor `/pr:create` compares against Linear's
  `updatedAt`. Always refresh it after an online write; never fabricate it.
- Status names must be **real** Linear states for the issue's team. If unsure,
  fetch them with `mcp__Linear_Lazco__list_issue_statuses` rather than inventing one.
- Linear writes are **outward-facing** — teammates see them. The queue means the
  significance gate already passed, so you may flush without re-confirming. But if a
  queued transition looks wrong (e.g. → `Done` while tests are failing), pause and
  ask the user first.

## Bootstrapping (no queue yet)

If `.linear.md` exists but there's no queue and you've just made clearly
milestone-level progress this turn (and the hook hasn't fired yet), it's fine to
update the issue + `.linear.md` directly using the same steps. The queue is the
automated path, not the only path.
