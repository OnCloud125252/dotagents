#!/bin/bash
# check-sync-queue.sh — SessionStart hook
# Nudge Claude to drain a non-empty tracker sync queue (Linear and/or GitHub PR)
# left by update-recent-work.sh, so milestone progress actually reaches the tracker.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

QUEUE_DIR="$CWD/.claude/recent-work"
LINEAR_QUEUE="$QUEUE_DIR/linear-sync-queue.md"
GITHUB_QUEUE="$QUEUE_DIR/github-sync-queue.md"

pending=""
[ -s "$LINEAR_QUEUE" ] && pending="${pending} the Linear sync queue (drain per the linear-md-sync rule);"
[ -s "$GITHUB_QUEUE" ] && pending="${pending} the GitHub PR sync queue (drain per the github-pr-sync rule);"

[ -z "$pending" ] && exit 0

jq -n --arg ctx "Unsynced tracker progress is pending —${pending} flush the queue(s) before the session ends so milestone progress reaches the tracker. If a destination is missing (no open PR / no linked issue), ask the user instead of dropping the notes." \
  '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'

exit 0
