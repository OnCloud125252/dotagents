#!/bin/bash
# update-recent-work.sh — Stop hook
# Reads recent conversation history, sends to Claude Sonnet to summarize,
# and conditionally updates .claude/RECENT_WORK.md (with file locking).

# Prevent recursive invocation (inner claude -p also triggers Stop hook)
[ "${RECENT_WORK_UPDATING:-}" = "1" ] && exit 0

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Bail if missing critical info
[ -z "$CWD" ] || [ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Only operate if project has a .claude directory
[ -d "$CWD/.claude" ] || exit 0

RECENT_WORK_FILE="$CWD/.claude/RECENT_WORK.md"
LOCK_DIR="$CWD/.claude/.recent_work.lock"
COOLDOWN_FILE="$CWD/.claude/.recent_work_last_update"

# ---------- Cooldown (skip if updated < 3 minutes ago) ----------
if [ -f "$COOLDOWN_FILE" ]; then
  LAST_UPDATE=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  if [ $(( NOW - LAST_UPDATE )) -lt 180 ]; then
    exit 0
  fi
fi

# ---------- Extract recent conversation ----------
# Grab last 400 JSONL lines, filter to user/assistant text, truncate each msg,
# keep last 40 messages, cap total at 20 KB.
RECENT_HISTORY=$(tail -400 "$TRANSCRIPT_PATH" 2>/dev/null | jq -r '
  select(.type == "user" or .type == "assistant") |
  select(.message != null and .message.content != null) |
  {
    role: .type,
    text: (
      if (.message.content | type) == "string" then
        .message.content
      elif (.message.content | type) == "array" then
        [ .message.content[] | select(.type == "text") | .text ] | join("\n")
      else ""
      end
    )
  } |
  select(.text != null and (.text | length) > 0) |
  "\(.role): \(.text | .[0:500])"
' 2>/dev/null | tail -40 | head -c 20000)

# Nothing meaningful to summarize
[ -z "$RECENT_HISTORY" ] && exit 0

# ---------- Read existing RECENT_WORK.md ----------
EXISTING_CONTENT=""
if [ -f "$RECENT_WORK_FILE" ]; then
  EXISTING_CONTENT=$(cat "$RECENT_WORK_FILE" 2>/dev/null)
fi

# ---------- Build prompt ----------
read -r -d '' PROMPT <<'PROMPT_DELIM' || true
You summarize software project work sessions. Analyze the recent conversation and decide whether RECENT_WORK.md needs updating.

PURPOSE: RECENT_WORK.md gives new Claude Code sessions a factual snapshot of recent activity so the user does not have to re-explain context. It is shared across multiple concurrent sessions.

CONTENT GUIDELINES — what to include:
- What feature, bug, or task was worked on (describe the goal, not the approach)
- Which files and areas of the codebase were touched or are relevant
- What observable changes were made (created, modified, deleted, renamed)
- Current state of the work (e.g. "tests passing", "build broken due to X", "migration pending")
- Any errors, blockers, or unresolved problems encountered (state the symptom, not the fix)

CONTENT GUIDELINES — what to AVOID:
- Do NOT record reasoning, rationale, or "why" behind choices
- Do NOT recommend approaches, strategies, or solutions
- Do NOT include "next steps", "TODO", or suggestions for future work
- Do NOT evaluate whether an approach was good or bad
- Do NOT include opinions, preferences, or comparative judgements
- The summary must NEVER steer a future session toward or away from any particular solution

TONE: Write as a neutral, factual changelog. Think "git log", not "design doc".

FORMAT RULES:
1. If the conversation is trivial (greetings, simple questions, no real work), output EXACTLY: NO_UPDATE_NEEDED
2. Otherwise, output the FULL updated RECENT_WORK.md in markdown.
3. Merge new info with existing content — do NOT discard prior entries unless clearly superseded by newer work on the same thing.
4. Keep it concise (30-60 lines). Prefer bullet points over prose.
5. Include "Last updated: YYYY-MM-DD HH:MM" near the top.
6. Do NOT wrap the output in a code fence.
7. Organize by recency — most recent work first.
PROMPT_DELIM

if [ -n "$EXISTING_CONTENT" ]; then
  PROMPT="$PROMPT

--- CURRENT RECENT_WORK.md ---
$EXISTING_CONTENT
--- END CURRENT RECENT_WORK.md ---"
fi

PROMPT="$PROMPT

--- RECENT CONVERSATION ---
$RECENT_HISTORY
--- END RECENT CONVERSATION ---

Output either the single line NO_UPDATE_NEEDED or the full updated markdown (nothing else):"

# ---------- Call Sonnet ----------
RESULT=$(echo "$PROMPT" \
  | RECENT_WORK_UPDATING=1 claude -p --model sonnet --no-session-persistence 2>/dev/null) || exit 0

# Check response
case "$RESULT" in
  *NO_UPDATE_NEEDED*) exit 0 ;;
esac

[ -z "$RESULT" ] && exit 0

# ---------- Acquire lock (mkdir is atomic on POSIX) ----------
acquire_lock() {
  local attempts=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 15 ]; then
      # Break stale lock older than 120 s (macOS stat -f %m = mtime epoch)
      if [ -d "$LOCK_DIR" ]; then
        local lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo "0") ))
        if [ "$lock_age" -gt 120 ]; then
          rmdir "$LOCK_DIR" 2>/dev/null || true
          attempts=0
          continue
        fi
      fi
      return 1  # give up
    fi
    sleep 1
  done
  return 0
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! acquire_lock; then
  exit 0
fi
trap release_lock EXIT

# ---------- Write ----------
echo "$RESULT" > "$RECENT_WORK_FILE"
date +%s > "$COOLDOWN_FILE"

exit 0
