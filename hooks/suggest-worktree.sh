#!/bin/bash
# SessionStart hook — suggest worktree workflow and detect stale worktrees

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$CWD" ] && exit 0

# In a worktree, .git is a file (gitdir pointer) — already isolated, nothing to suggest.
[ -d "$CWD/.git" ] || exit 0

BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Detect stale worktrees (branches merged & deleted on remote) ---
STALE_MSG=""
git -C "$CWD" fetch origin --prune 2>/dev/null

STALE_LIST=""
while IFS= read -r line; do
  WT_PATH=$(echo "$line" | awk '{print $1}')
  WT_BRANCH=$(echo "$line" | sed 's/.*\[//' | sed 's/\]//')

  [ "$WT_BRANCH" = "main" ] || [ "$WT_BRANCH" = "master" ] && continue
  # Skip the main worktree (not under .claude/worktrees/)
  echo "$WT_PATH" | grep -q '\.claude/worktrees/' || continue

  REMOTE_EXISTS=$(git -C "$CWD" ls-remote --heads origin "$WT_BRANCH" 2>/dev/null | wc -l | tr -d ' ')
  AHEAD=$(git -C "$CWD" rev-list --count "origin/main..$WT_BRANCH" 2>/dev/null || echo "?")

  if [ "$REMOTE_EXISTS" = "0" ] && [ "$AHEAD" = "0" ]; then
    DIR_NAME=$(basename "$WT_PATH")
    STALE_LIST="${STALE_LIST}  - \`${DIR_NAME}\` (branch: \`${WT_BRANCH}\`) — merged & remote deleted
"
  fi
done < <(git -C "$CWD" worktree list 2>/dev/null | grep -v "bare" | tail -n +2)

if [ -n "$STALE_LIST" ]; then
  STALE_MSG="

Also mention to the user: the following worktrees appear stale (remote branch deleted, no unique commits ahead of origin/main). Suggest running \`/worktree:cleanup\`:

${STALE_LIST}"
fi

# --- Suggest worktree creation ---
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  MSG='IMPORTANT — BLOCKING REQUIREMENT: The user is on the main branch and not in a worktree. Before responding to ANY user request that involves code changes, you MUST first inform the user and suggest using the worktree workflow:

"You'\''re currently on the main branch. I recommend creating a worktree for isolation before making changes:  /worktree:create <Linear-issue-or-branch>"

Do NOT start making changes directly on the main branch. After the user responds (whether they agree or decline), proceed with their original request.'
else
  MSG="IMPORTANT — BLOCKING REQUIREMENT: The user is on branch \"$BRANCH\" but not in a worktree. Before responding to ANY user request that involves code changes, you MUST first inform the user and suggest moving to a worktree:

\"You're on branch \`$BRANCH\` but not in a worktree. Worktrees provide isolation and auto-configure git hooks. Want me to run  /worktree:create $BRANCH  to set one up?\"

After the user responds (whether they agree or decline), proceed with their original request."
fi

MSG="${MSG}${STALE_MSG}"

jq -n --arg ctx "$MSG" \
  '{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": $ctx } }'

exit 0
