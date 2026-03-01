#!/usr/bin/env bash
input=$(cat)
export CCSTATUSLINE_CLAUDE_SESSION_ID=$(jq -r '.session_id' <<< "$input")
echo "$input" | bunx -y ccstatusline@latest
