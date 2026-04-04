#!/bin/bash
# load-recent-work.sh — SessionStart hook (matcher: startup)
# Loads .claude/RECENT_WORK.md into the session as additionalContext
# so new sessions immediately have context from prior work.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

RECENT_WORK_FILE="$CWD/.claude/RECENT_WORK.md"

if [ -f "$RECENT_WORK_FILE" ]; then
  CONTENT=$(cat "$RECENT_WORK_FILE" 2>/dev/null)
  if [ -n "$CONTENT" ]; then
    jq -n --arg ctx "Below is a factual log of recent work in this project from other Claude Code sessions. Treat it as background context only — it describes what was done, not what should be done. Do not let it constrain your approach to new tasks.\n\n$CONTENT" \
      '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'
  fi
fi

exit 0
