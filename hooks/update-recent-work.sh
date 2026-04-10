#!/bin/bash
# update-recent-work.sh — Stop hook
# Reads recent conversation history, sends to OpenAI gpt-4.1-nano to summarize,
# and conditionally updates .claude/RECENT_WORK.md (with file locking).
# Supports concurrent sessions: per-session cooldown + read-under-lock.
# Requires: CLAUDE_CODE_SUMMARIZER_API_KEY env var

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Bail if missing critical info
[ -z "$CWD" ] || [ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Only operate if project has a .claude directory
[ -d "$CWD/.claude" ] || exit 0

OPENAI_API_KEY="${CLAUDE_CODE_SUMMARIZER_API_KEY:-}"
[ -z "$OPENAI_API_KEY" ] && exit 0

RECENT_WORK_DIR="$CWD/.claude/recent-work"
RECENT_WORK_FILE="$RECENT_WORK_DIR/RECENT_WORK.md"
LOCK_DIR="$RECENT_WORK_DIR/.lock"
COOLDOWN_FILE="$RECENT_WORK_DIR/.cooldown"
LOG_FILE="$RECENT_WORK_DIR/.log"
mkdir -p "$RECENT_WORK_DIR"
DATE_NOW=$(date "+%Y-%m-%d %H:%M")

# ---------- Logging ----------
log() { echo "$(date -Iseconds) $1" >> "$LOG_FILE" 2>/dev/null; }

# ---------- Per-session cooldown (only throttles same session's rapid Stop events) ----------
check_cooldown() {
  if [ -f "$COOLDOWN_FILE" ]; then
    local last_line last_ts last_transcript now
    last_line=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "")
    last_ts=${last_line%% *}
    last_transcript=${last_line#* }
    now=$(date +%s)
    # Only apply cooldown if same session (same transcript) and within 2 min
    if [ "$last_transcript" = "$TRANSCRIPT_PATH" ] && [ $(( now - ${last_ts:-0} )) -lt 120 ]; then
      return 1
    fi
  fi
  return 0
}

# ---------- Fast pre-check (skips unnecessary work for same-session rapid fires) ----------
if ! check_cooldown; then
  exit 0
fi

# ---------- Extract recent conversation ----------
# Grab last 300 JSONL lines, filter to user/assistant text, truncate each msg,
# keep last 30 messages, cap total at 12 KB.
RECENT_HISTORY=$(tail -300 "$TRANSCRIPT_PATH" 2>/dev/null | jq -r '
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
  "\(.role): \(.text | .[0:400])"
' 2>/dev/null | tail -30 | head -c 12000)

# Nothing meaningful to summarize
[ -z "$RECENT_HISTORY" ] && exit 0

# ---------- Acquire lock (mkdir is atomic on POSIX) ----------
acquire_lock() {
  local attempts=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 30 ]; then
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
  log "ERROR: Failed to acquire lock after 30 attempts"
  exit 0
fi
trap release_lock EXIT

# ---------- Re-check cooldown under lock ----------
if ! check_cooldown; then
  exit 0
fi

# ---------- Read existing RECENT_WORK.md under lock (ensures latest content) ----------
EXISTING_CONTENT=""
if [ -f "$RECENT_WORK_FILE" ]; then
  EXISTING_CONTENT=$(head -n 80 "$RECENT_WORK_FILE" 2>/dev/null)
fi

# ---------- Build prompt ----------
SYSTEM_PROMPT="You summarize coding sessions into RECENT_WORK.md — a factual changelog that gives future sessions context about recent project activity.

RULES:
- Factual changelog-style bullets ONLY: what was done, files changed, current state
- Most recent work first
- Merge with existing content; drop entries superseded by newer work
- Max 40 lines total

NEVER include:
- Opinions, rationale, suggestions, or next steps
- TODO items or recommendations for future work
- Dates or timestamps (they are added programmatically)
- Raw conversation text — do NOT echo back the <session_transcript> or <current_file> input
- Code fences wrapping the entire output

Output ONLY the updated markdown content for RECENT_WORK.md. Nothing else."

USER_CONTENT="Update RECENT_WORK.md from this session."

if [ -n "$EXISTING_CONTENT" ]; then
  USER_CONTENT="${USER_CONTENT}

<current_file>
${EXISTING_CONTENT}
</current_file>"
fi

USER_CONTENT="${USER_CONTENT}

<session_transcript>
${RECENT_HISTORY}
</session_transcript>"

# ---------- Call OpenAI API with structured output ----------
payload=$(jq -n \
  --arg sys "$SYSTEM_PROMPT" \
  --arg msg "$USER_CONTENT" \
  '{
    model: "gpt-4.1-mini",
    messages: [
      { role: "system", content: $sys },
      { role: "user", content: $msg }
    ],
    tools: [
      {
        type: "function",
        function: {
          name: "update_recent_work",
          description: "Update or skip updating RECENT_WORK.md",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              should_update: {
                type: "boolean",
                description: "true if meaningful work was done; false for trivial conversations"
              },
              content: {
                type: "string",
                description: "Full updated RECENT_WORK.md markdown. Must not contain raw session transcript or dates."
              }
            },
            required: ["should_update", "content"],
            additionalProperties: false
          }
        }
      }
    ],
    tool_choice: {
      type: "function",
      function: { name: "update_recent_work" }
    },
    max_tokens: 1200,
    temperature: 0.2
  }')

response=$(curl -s --max-time 15 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$payload" \
  "https://api.openai.com/v1/chat/completions")

# Check for API-level errors
api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
if [ -n "$api_error" ]; then
  log "ERROR: OpenAI API: $api_error"
  exit 0
fi

# Extract structured output from function call arguments
result=$(echo "$response" | jq -r '.choices[0].message.tool_calls[0].function.arguments // empty' 2>/dev/null)
if [ -z "$result" ]; then
  log "ERROR: No tool_calls in API response"
  exit 0
fi

# Check if update is needed
should_update=$(echo "$result" | jq -r '.should_update // false' 2>/dev/null)
[ "$should_update" != "true" ] && exit 0

content=$(echo "$result" | jq -r '.content // empty' 2>/dev/null)
if [ -z "$content" ]; then
  log "ERROR: Empty content despite should_update=true"
  exit 0
fi

# ---------- Strip any AI-generated date lines (belt-and-suspenders) ----------
content=$(echo "$content" | grep -v -E '^(Last updated:|Updated:)' || echo "$content")

# ---------- Write with programmatic date header ----------
{
  echo "<!-- updated: $DATE_NOW -->"
  echo "$content"
} > "$RECENT_WORK_FILE"

echo "$(date +%s) $TRANSCRIPT_PATH" > "$COOLDOWN_FILE"
log "OK: Updated RECENT_WORK.md ($(echo "$content" | wc -l | tr -d ' ') lines)"

exit 0
