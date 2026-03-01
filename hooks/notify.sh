#!/bin/bash
# Claude Code notification hook using growlrrr (grrr)
# Reads JSON from stdin to determine event type and build dynamic messages

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

    # Extract last assistant message, truncate to 200 chars for notification
    last_msg=$(echo "$input" | jq -r '.last_assistant_message // "Task complete."')
    claude_session_id=$(echo "$input" | jq -r '.session_id // "claude-session"')
    if [ ${#last_msg} -gt 200 ]; then
      message="$(echo "$last_msg" | head -c 200) ......"$'\n'"[See terminal for full message]"
    else
      message="$last_msg"
    fi

    grrr \
      --title "Claude Code @$project" \
      --subtitle "Operation Finished" \
      --sound Hero \
      --appId claude-code \
      --execute "open -b com.github.wez.wezterm" \
      --threadId "$claude_session_id" \
      "$message"
    ;;

  Notification)
    message=$(echo "$input" | jq -r '.message // "Claude needs your attention"')
    claude_session_id=$(echo "$input" | jq -r '.session_id // "claude-session"')

    grrr \
      --title "Claude Code @$project" \
      --subtitle "Input Needed" \
      --sound Glass \
      --appId claude-code \
      --execute "open -b com.github.wez.wezterm" \
      --threadId "$claude_session_id" \
      "$message"
    ;;
esac

exit 0
