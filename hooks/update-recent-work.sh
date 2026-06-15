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
# Linear offline→online sync: the worktree's offline mirror, and the append-only
# queue this hook feeds (drained by Claude via the linear-md-sync rule). The queue
# lives under .claude/recent-work/ so it inherits the same gitignore + mkdir as RECENT_WORK.md.
LINEAR_MD_FILE="$CWD/.linear.md"
LINEAR_QUEUE_FILE="$RECENT_WORK_DIR/linear-sync-queue.md"
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
- Max 25 lines total

NEVER include:
- Opinions, rationale, suggestions, or next steps
- TODO items or recommendations for future work
- Dates or timestamps (they are added programmatically)
- Raw conversation text — do NOT echo back the <session_transcript> or <current_file> input
- Code fences wrapping the entire output

Put the updated RECENT_WORK.md markdown in the \`content\` field. If no <linear_issue> block appears in the input, set \`linear\` to {significant:false, status_change:null, progress_note:null}."

# The Linear-significance rubric is ~200 tokens. Append it ONLY when this worktree
# is linked to a Linear issue — in other repos the schema descriptions plus the base
# prompt's one-line fallback already make the model null out \`linear\`, so the rubric
# would be pure waste on every unrelated Stop event.
if [ -f "$LINEAR_MD_FILE" ]; then
  SYSTEM_PROMPT="${SYSTEM_PROMPT}

LINEAR ISSUE SYNC (the \`linear\` field):
- This worktree is linked to a Linear issue, given in the input as a <linear_issue> block (frontmatter + acceptance criteria).
- Set linear.significant=true ONLY for milestone-level progress on that issue: a large or completed code change, a resolved design decision, a status transition, a newly-found blocker, or work that completes or clearly advances an acceptance criterion. Routine intermediate edits, exploration, reading, and small fixes are NOT significant.
- linear.status_change: a Linear status name (e.g. \"In Review\", \"Done\") ONLY if the work clearly implies a transition away from the status shown in <linear_issue>; otherwise null.
- linear.progress_note: when significant, ONE concise sentence (<=160 chars) describing the milestone, suitable to post as a Linear comment; otherwise null."
fi

USER_CONTENT="Update RECENT_WORK.md from this session."

if [ -n "$EXISTING_CONTENT" ]; then
  USER_CONTENT="${USER_CONTENT}

<current_file>
${EXISTING_CONTENT}
</current_file>"
fi

# Include only the DECISION-RELEVANT parts of the linked Linear issue: the
# frontmatter (current status) + the Acceptance Criteria checklist (what progress
# would advance). Deliberately skips the verbose Original Description — it's static
# background that doesn't help judge THIS turn's significance and costs ~4x the
# tokens. awk is line-based (no multi-byte UTF-8 splitting); head -n 40 is a safety cap.
LINEAR_CONTEXT=""
if [ -f "$LINEAR_MD_FILE" ]; then
  LINEAR_CONTEXT=$(awk '
    NR==1 && $0=="---" { fm=1; print; next }
    fm==1 { print; if ($0=="---") fm=0; next }
    /^## Acceptance Criteria/ { ac=1; print; next }
    ac==1 && /^## / { ac=0 }
    ac==1 { print }
  ' "$LINEAR_MD_FILE" 2>/dev/null | head -n 40)
fi
if [ -n "$LINEAR_CONTEXT" ]; then
  USER_CONTENT="${USER_CONTENT}

<linear_issue>
${LINEAR_CONTEXT}
</linear_issue>"
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
              },
              linear: {
                type: "object",
                description: "Linear issue sync decision. Acts only when a <linear_issue> block is present in the input.",
                properties: {
                  significant: {
                    type: "boolean",
                    description: "true ONLY for milestone-level progress on the linked Linear issue (large/complete change, resolved decision, status transition, new blocker, acceptance criterion advanced). false otherwise, and false when no <linear_issue> block is present."
                  },
                  status_change: {
                    type: ["string", "null"],
                    description: "New Linear status name if the work implies a transition from the current status; otherwise null."
                  },
                  progress_note: {
                    type: ["string", "null"],
                    description: "One concise sentence (<=160 chars) to post as a Linear comment when significant; otherwise null."
                  }
                },
                required: ["significant", "status_change", "progress_note"],
                additionalProperties: false
              }
            },
            required: ["should_update", "content", "linear"],
            additionalProperties: false
          }
        }
      }
    ],
    tool_choice: {
      type: "function",
      function: { name: "update_recent_work" }
    },
    max_tokens: 700,
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

# ---------- RECENT_WORK.md (only if the model flagged meaningful work) ----------
should_update=$(echo "$result" | jq -r '.should_update // false' 2>/dev/null)
if [ "$should_update" = "true" ]; then
  content=$(echo "$result" | jq -r '.content // empty' 2>/dev/null)
  if [ -z "$content" ]; then
    log "ERROR: Empty content despite should_update=true"
  else
    # Strip any AI-generated date lines (belt-and-suspenders)
    content=$(echo "$content" | grep -v -E '^(Last updated:|Updated:)' || echo "$content")
    # Write with programmatic date header
    {
      echo "<!-- updated: $DATE_NOW -->"
      echo "$content"
    } > "$RECENT_WORK_FILE"
    log "OK: Updated RECENT_WORK.md ($(echo "$content" | wc -l | tr -d ' ') lines)"
  fi
fi

# ---------- Linear online-sync queue (only if this worktree is linked to an issue) ----------
# Append-only: Claude is the sole writer of .linear.md; this hook never mutates it.
# The linear-md-sync rule drains this queue to Linear via MCP, then deletes it.
if [ -f "$LINEAR_MD_FILE" ]; then
  linear_significant=$(echo "$result" | jq -r '.linear.significant // false' 2>/dev/null)
  if [ "$linear_significant" = "true" ]; then
    linear_note=$(echo "$result" | jq -r '.linear.progress_note // empty' 2>/dev/null)
    linear_status=$(echo "$result" | jq -r '.linear.status_change // empty' 2>/dev/null)
    if [ -n "$linear_note" ]; then
      issue_id=$(grep -m1 '^issue:' "$LINEAR_MD_FILE" 2>/dev/null | sed 's/^issue:[[:space:]]*//' | tr -d '\r')
      # Write a one-time header when the queue is first created this cycle
      if [ ! -f "$LINEAR_QUEUE_FILE" ]; then
        {
          echo "<!-- Linear online-sync queue for ${issue_id:-unknown}. Each entry = one turn flagged as significant by update-recent-work.sh."
          echo "     Claude: per the linear-md-sync rule, push these to Linear via MCP, update .linear.md (status + last_synced), then delete this file. -->"
          echo ""
        } > "$LINEAR_QUEUE_FILE"
      fi
      {
        echo "## ${DATE_NOW} — status: ${linear_status:-(unchanged)}"
        echo "${linear_note}"
        echo ""
      } >> "$LINEAR_QUEUE_FILE"
      log "OK: Queued Linear sync (${issue_id:-unknown}) status=${linear_status:-unchanged}"
    fi
  fi
fi

# Throttle this session's rapid Stop events (set once, regardless of which writes happened)
echo "$(date +%s) $TRANSCRIPT_PATH" > "$COOLDOWN_FILE"

exit 0
