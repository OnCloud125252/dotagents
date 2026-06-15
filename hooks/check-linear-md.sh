#!/bin/bash
# SessionStart hook — two jobs for worktrees:
#   1. If .linear.md is MISSING → ask the user to link a Linear issue (blocking).
#   2. If .linear.md EXISTS and the Stop hook has queued progress for online sync
#      → nudge Claude to flush the queue to Linear via MCP (non-blocking).

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

# Only applies inside a worktree (.git is a file, not a directory)
[ -f "$CWD/.git" ] || exit 0

# .linear.md exists — nudge only if there's progress queued for online sync.
if [ -f "$CWD/.linear.md" ]; then
  LINEAR_QUEUE="$CWD/.claude/recent-work/linear-sync-queue.md"
  if [ -s "$LINEAR_QUEUE" ]; then
    jq -n --arg ctx 'NOTE — pending Linear sync: this worktree has progress queued for online sync at .claude/recent-work/linear-sync-queue.md (written by the update-recent-work Stop hook when it judged work milestone-significant). Per the linear-md-sync rule, drain that queue: rename it aside, push each queued status/comment to the Linear issue via the Linear MCP, then update .linear.md (status + last_synced UTC) and delete the queue file. You may finish the user'"'"'s current request first if it is unrelated, then flush before ending the session. Never discard the queue without syncing it.' \
      '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'
  fi
  exit 0
fi

jq -n --arg ctx 'IMPORTANT — BLOCKING REQUIREMENT: Before responding to ANY user request, you MUST first inform the user that this worktree is not linked to a Linear issue and ask if they want to set one up. Say:

"This worktree isn'\''t linked to a Linear issue yet. Would you like to provide a Linear issue ID (e.g. PLA-1234) or URL so I can set up .linear.md for automatic status sync during /pr:create?"

After the user responds (whether they provide an ID or decline), proceed with their original request.

If the user provides an ID or URL, use the Linear MCP tools to fetch the issue and hydrate .linear.md from the Linear template (resolved by the consumer: project-local `.claude/templates/linear.md` first, otherwise `~/.agents/templates/linear.md`).' \
  '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'

exit 0
