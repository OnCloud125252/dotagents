#!/usr/bin/env bash
# Resolve the claude-peers peer ID for the current Claude Code session.
#
# The broker exposes no "who am I" endpoint and never sees Claude's session_id.
# ccstatusline also runs custom commands with a detached controlling terminal, so
# the session tty (which the MCP server registers under) is unavailable here. The
# stable bridge is process ancestry: we walk up to our Claude Code process and
# match the peer whose MCP-server process is its direct child — unique per session
# even when several sessions share one working directory.

port="${CLAUDE_PEERS_PORT:-7899}"

peers=$(curl -s --max-time 1 \
  -X POST "http://127.0.0.1:${port}/list-peers" \
  -H 'Content-Type: application/json' \
  -d '{"scope":"machine","cwd":"/","git_root":null}' 2>/dev/null)

[ -z "$peers" ] && exit 0

find_claude_pid() {
  local pid=$$ ppid comm
  for _ in {1..20}; do
    read -r ppid comm < <(ps -o ppid=,comm= -p "$pid" 2>/dev/null)
    [ -z "$ppid" ] && return
    [ "${comm##*/}" = "claude" ] && { echo "$pid"; return; }
    pid=$ppid
    [ "$pid" -le 1 ] 2>/dev/null && return
  done
}

claude_pid=$(find_claude_pid)

id=""
if [ -n "$claude_pid" ]; then
  id=$(jq -r '.[] | select(.pid != null) | "\(.id) \(.pid)"' <<< "$peers" 2>/dev/null \
    | while read -r peer_id peer_pid; do
        peer_ppid=$(ps -o ppid= -p "$peer_pid" 2>/dev/null | tr -d ' ')
        [ "$peer_ppid" = "$claude_pid" ] && { echo "$peer_id"; break; }
      done)
fi

# Fallback when ancestry can't reach a Claude process (unusual launchers): match
# by cwd, but only when a single session is registered in this directory.
if [ -z "$id" ]; then
  id=$(jq -r --arg c "$(pwd)" 'map(select(.cwd == $c)) | if length == 1 then .[0].id else empty end' <<< "$peers" 2>/dev/null)
fi

printf '%s' "$id"
exit 0
