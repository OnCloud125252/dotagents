#!/bin/bash
# Claude Code notification hook using growlrrr (grrr)
# Reads JSON from stdin to determine event type and build dynamic messages

# Filter notification message for clean display.
# Each stage is a simple pipe — add new filters by appending a pipe stage.
filter_message() {
  sed 's/─//g' \
    | tr -d '\t' \
    | sed 's/  */ /g' \
    | sed 's/^ *//; s/ *$//' \
    | sed '/^$/d'
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Extract last user input from the session JSONL file.
get_last_user_input() {
  local session_id="$1"
  local session_file
  session_file=$(echo ~/.claude/projects/*/"${session_id}.jsonl")
  local jq_filter='
    select(
      .type == "user" and
      .message.role == "user" and
      (.message.content | type == "string")
    ) | .message.content |
    if (startswith("<") | not) and (startswith("Caveat") | not) then
      .
    elif test("<command-name>") then
      capture("<command-name>(?<cmd>[^<]+)</command-name>") | .cmd |
      select(. != "/clear" and . != "/exit")
    else
      empty
    end
  '
  jq -r "$jq_filter" "$session_file" 2>/dev/null | tail -1
}

# Summarize a message and generate subtitle via OpenAI gpt-4.1-nano.
# Usage: echo "msg" | summarize_message <stop|notification> [user_input]
# Returns JSON: {"subtitle":"...","message":"..."}
# Falls back to defaults if the API key is missing or the call fails.
summarize_message() {
  "$SCRIPT_DIR/../helpers/summarize.sh" "$1" "$2"
}

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // "Unknown"')
project=$(echo "$input" | jq -r '.cwd // ""' | xargs basename 2>/dev/null || echo "")

case "$event" in
  Stop)
    # Guard against infinite loops
    stop_active=$(echo "$input" | jq -r '.stop_hook_active // false')
    if [ "$stop_active" = "true" ]; then
      exit 0
    fi

    # Extract last assistant message, skip if empty
    last_msg=$(echo "$input" | jq -r '.last_assistant_message // ""')
    if [ -z "$last_msg" ]; then
      exit 0
    fi
    claude_session_id=$(echo "$input" | jq -r '.session_id // "claude-session"')
    user_input=$(get_last_user_input "$claude_session_id")
    if [ ${#last_msg} -gt 200 ]; then
      message="$(echo "$last_msg" | head -c 200) ......"$'\n'"[See terminal for full message]"
    else
      message="$last_msg"
    fi
    summary_json=$(echo "$message" | summarize_message stop "$user_input")
    subtitle=$(echo "$summary_json" | jq -r '.subtitle' | filter_message)
    message=$(echo "$summary_json" | jq -r '.message' | filter_message)

    grrr \
      --title "Claude Code @$project" \
      --subtitle "$subtitle" \
      --sound Hero \
      --appId claude-code \
      --execute "open -b com.github.wez.wezterm" \
      --threadId "$claude_session_id" \
      "$message"
    ;;

  Notification)
    message=$(echo "$input" | jq -r '.message // ""')
    if [ -z "$message" ]; then
      exit 0
    fi
    notification_type=$(echo "$input" | jq -r '.type // ""')
    claude_session_id=$(echo "$input" | jq -r '.session_id // "claude-session"')

    if [ "$notification_type" = "idle_prompt" ]; then
      # Simple fixed notification — no LLM, visually distinct from stop events
      grrr \
        --title "Claude Code @$project" \
        --subtitle "Waiting for Input" \
        --sound Tink \
        --appId claude-code \
        --execute "open -b com.github.wez.wezterm" \
        --threadId "$claude_session_id" \
        "Session is idle — check terminal for pending prompts"
    else
      # LLM-summarized notification for all other event types
      user_input=$(get_last_user_input "$claude_session_id")
      summary_json=$(echo "$message" | summarize_message notification "$user_input")
      subtitle=$(echo "$summary_json" | jq -r '.subtitle' | filter_message)
      message=$(echo "$summary_json" | jq -r '.message' | filter_message)

      grrr \
        --title "Claude Code @$project" \
        --subtitle "$subtitle" \
        --sound Glass \
        --appId claude-code \
        --execute "open -b com.github.wez.wezterm" \
        --threadId "$claude_session_id" \
        "$message"
    fi
    ;;
esac

exit 0
