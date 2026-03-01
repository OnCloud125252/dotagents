#!/usr/bin/env bash
session_file=$(echo ~/.claude/projects/*/"${CCSTATUSLINE_CLAUDE_SESSION_ID}.jsonl")

jq_filter='
  select(
    .type == "user" and
    .message.role == "user" and
    (.message.content | type == "string")
  ) | .message.content |
  if (startswith("<") | not) and (startswith("Caveat") | not) then
    .
  elif test("<command-name>") then
    capture("<command-name>(?<cmd>[^<]+)</command-name>") | .cmd |
    select(. != "/clear")
  else
    empty
  end
'

output=$(jq -r "$jq_filter" "$session_file" 2>/dev/null | tail -1)
echo "${output:-N/A}"
