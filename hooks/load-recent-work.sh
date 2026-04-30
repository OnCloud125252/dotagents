#!/bin/bash
# load-recent-work.sh — SessionStart hook (matcher: startup)
# Loads .claude/RECENT_WORK.md into the session as additionalContext
# so new sessions immediately have context from prior work.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

RECENT_WORK_FILE="$CWD/.claude/recent-work/RECENT_WORK.md"

if [ -f "$RECENT_WORK_FILE" ]; then
  # Line-based cap (~25 lines) to avoid splitting multi-byte UTF-8 characters
  CONTENT=$(head -n 25 "$RECENT_WORK_FILE" 2>/dev/null)
  if [ -n "$CONTENT" ]; then
    jq -n --arg ctx "Recent project activity (read-only context — what was done, not what to do next):\n\n$CONTENT" \
      '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'
  fi
fi

exit 0
