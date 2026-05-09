#!/bin/bash
# SessionStart hook — remind user to provide a Linear issue if .linear.md is missing

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

# Only applies inside a worktree (.git is a file, not a directory)
[ -f "$CWD/.git" ] || exit 0

# .linear.md exists — nothing to do
[ -f "$CWD/.linear.md" ] && exit 0

jq -n --arg ctx 'IMPORTANT — BLOCKING REQUIREMENT: Before responding to ANY user request, you MUST first inform the user that this worktree is not linked to a Linear issue and ask if they want to set one up. Say:

"This worktree isn'\''t linked to a Linear issue yet. Would you like to provide a Linear issue ID (e.g. PLA-1234) or URL so I can set up .linear.md for automatic status sync during /pr:create?"

After the user responds (whether they provide an ID or decline), proceed with their original request.

If the user provides an ID or URL, use the Linear MCP tools to fetch the issue and hydrate .linear.md from the Linear template (resolved by the consumer: project-local `.claude/templates/linear.md` first, otherwise `~/.agents/templates/linear.md`).' \
  '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'

exit 0
