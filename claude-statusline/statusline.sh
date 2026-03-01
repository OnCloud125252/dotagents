#!/usr/bin/env bash
input=$(cat) && export CCSTATUSLINE_CLAUDE_SESSION_ID=$(echo "$input" | jq -r '.session_id') && echo "$input" | bunx -y ccstatusline@latest
