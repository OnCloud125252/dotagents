#!/usr/bin/env bash
session_file=$(echo ~/.claude/projects/*/"${CCSTATUSLINE_CLAUDE_SESSION_ID}.jsonl")

jq_filter='
  select(
    .type == "user" and
    .message.role == "user" and
    (.message.content | type == "string") and
    (.message.content | startswith("<") | not) and
    (.message.content | startswith("Caveat") | not)
  ) | .message.content
'

output=$(jq -r "$jq_filter" "$session_file" 2>/dev/null | tail -1)
echo "${output:-N/A}"
