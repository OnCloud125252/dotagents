---
name: Create Pull Request
description: Push current branch and create a GitHub pull request with smart defaults
argument-hint: [--base main] [--draft] [--title "title"]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git push:*), Bash(git rev-parse:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(pbcopy), Bash(claude *), Bash(date *), Read, Write, AskUserQuestion, mcp__Linear*__get_issue, mcp__Linear*__save_issue, mcp__Linear*__save_comment, mcp__Linear*__list_issue_statuses
model: claude-sonnet-4-6
---

Create a GitHub pull request for the current branch.

### Arguments

Parse `$ARGUMENTS` to extract:

- **--base** or **-b**: Optional. Base branch (default: `main`)
- **--draft** or **-d**: Optional. Create as draft PR
- **--title** or **-t**: Optional. Override the PR title
- **--no-push**: Optional. Skip pushing (assume already pushed)

### Process

1. **Gather Context** (run these in parallel):
   - `git status` — check for uncommitted changes
   - `git rev-parse --abbrev-ref HEAD` — get current branch name
   - `git log --oneline <base>..HEAD` — list all commits on this branch (where `<base>` is from `--base`, default `main`)
   - `git diff <base>...HEAD --stat` — summarize changed files
   - `git branch -vv | grep '^\*'` — check remote tracking

2. **Detect Linear Issue** (from the branch name):
   - Check if the branch name contains a Linear issue ID — a segment matching 2-5 letters, a hyphen, then digits (e.g., `sei-381`, `PLA-1004`). Match case-insensitively.
   - If found, uppercase it (e.g., `sei-381` → `SEI-381`) and call `mcp__Linear*__get_issue` to fetch the issue's `title`, `identifier`, and `url`.
   - If no issue ID is found in the branch name, or the fetch fails, skip this step and proceed without Linear context.

3. **Safety Checks**:
   - If there are uncommitted changes, warn the user and ask whether to proceed
   - If on `main` or `master`, refuse to create PR from the base branch
   - If no commits ahead of base, inform user there's nothing to PR

4. **Push if Needed**:
   - If branch has no upstream or is ahead of remote, push with `-u origin <branch>`
   - If `--no-push` is set, skip this step

5. **Linear Sync Flow** (only if `.linear.md` exists in the worktree root):

   Use the Read tool to check if `.linear.md` exists at the repo root. If it does not exist, skip this entire step silently and proceed to step 6.

   If `.linear.md` exists, read and parse it. The file has YAML frontmatter (between `---` lines) with keys `issue`, `url`, `title`, `status`, `worktree`, `last_synced`. If any of `issue`, `url`, or `last_synced` is missing, warn the user that the file is malformed, skip sync, and proceed to step 6.

   **Step A — Conflict detection:**
   Call `mcp__Linear*__get_issue` with the `issue` ID from frontmatter. Compare the issue's `updatedAt` timestamp against `last_synced`. If `updatedAt` is newer than `last_synced`, use AskUserQuestion to present three options:
   - "Refresh from Linear" — re-fetch the issue, overwrite `.linear.md` with fresh data and a new `last_synced`, then continue
   - "Use stale cache" — proceed with the existing `.linear.md` as-is
   - "Cancel sync" — skip the entire sync flow, proceed to PR creation

   If `updatedAt` is equal to or older than `last_synced`, skip this prompt and continue.

   **Step B — Sub-Claude review:**
   1. Fetch available statuses: call `mcp__Linear*__list_issue_statuses` for the issue's team. If the call fails, set `available_statuses` to an empty array.
   2. Gather git context:
      - `git log --oneline main..HEAD` (commit history)
      - `git diff main...HEAD --stat` (changed files summary)
   3. Invoke sub-Claude:

      ```bash
      claude -p --output-format json "You are a project management assistant. Compare the Linear issue metadata against the git history and determine if the issue needs updating.

      LINEAR ISSUE (.linear.md):
      <contents of .linear.md>

      GIT LOG (commits on this branch):
      <git log output>

      GIT DIFF STAT:
      <git diff stat output>

      AVAILABLE STATUSES: <JSON array of status names>

      Return JSON with this exact shape:
      {
        \"title_drift\": { \"changed\": bool, \"suggested_title\": string | null },
        \"description_drift\": { \"changed\": bool, \"suggested_description\": string | null },
        \"comment_worth_it\": { \"yes\": bool, \"draft\": string | null },
        \"status_change\": string | null
      }

      Rules:
      - title_drift.changed=true only if the work clearly diverged from the original title
      - description_drift.changed=true only if significant implementation decisions differ from the description
      - comment_worth_it.yes=true if a progress summary comment would be valuable (always draft in Traditional Chinese zh-TW)
      - status_change must be null or exactly one of the AVAILABLE STATUSES values
      - If nothing needs changing, set all to unchanged/null/false
      - Return ONLY valid JSON, no markdown"
      ```

   4. Parse the JSON output. If parsing fails or `status_change` is not in the available statuses list, warn the user ("Linear sync skipped — please update Linear manually"), skip to step 6.
   5. If all fields indicate no change (`changed: false`, `yes: false`, `status_change: null`), log "No drift detected" and skip to step 6.

   **Step C — Per-field approval:**
   Build a list of proposed changes from the non-empty fields in the sub-Claude response. Use AskUserQuestion to present a multi-select checklist. Each option is independently selectable:
   - "Update title" (show current → suggested)
   - "Update description" (show summary of changes)
   - "Post comment" (show draft text)
   - "Set status to <status>" (show current → new)
   - "Skip all"

   Only include options where the sub-Claude proposed a change. If the user selects "Skip all" or no options, skip to step 6.

   **Step D — Write-back:**
   For each approved field:
   - **Title and/or description**: Call `mcp__Linear*__save_issue` with the updated fields
   - **Comment**: Call `mcp__Linear*__save_comment` with the draft text and the issue ID
   - **Status**: Call `mcp__Linear*__save_issue` with the new state name

   If any write fails, log the failure but continue with remaining writes. Do not abort PR creation.

   **Step E — Re-hydration:**
   If at least one write in Step D succeeded:
   1. Re-fetch the issue via `mcp__Linear*__get_issue`
   2. Overwrite `.linear.md` with the fresh issue data using the Write tool
   3. Set `last_synced` to the current UTC time

   If all writes failed or no writes were attempted, leave `.linear.md` unchanged.

   **MCP unavailable**: If any MCP call in the sync flow fails due to the server being unreachable, display a warning ("Linear MCP unavailable — sync skipped"), skip the entire sync flow, and proceed to PR creation.

6. **Analyze Changes**:
   - Review ALL commits on the branch (`git log <base>..HEAD`), not just the latest
   - Review the full diff (`git diff <base>...HEAD`) to understand scope
   - Determine change type: feature, fix, refactor, docs, chore, etc.

7. **Generate PR Content**:
   - **Title**: Short (under 70 chars), prefixed with type.
     - If `--title` provided, use that instead (skip all generation below)
     - If a Linear issue was fetched: `<type>(<ISSUE-ID>): <Linear issue title>`
       - Example: `feat(SEI-381): Implement blacklist management`
       - The type prefix (`feat`, `fix`, etc.) is still determined from commit analysis
       - Shorten the Linear issue title if needed to stay under 70 chars
     - If no Linear issue: `<type>: <summary from commits>` (existing behavior)
   - **Body**: Use this format:

   ```
   ## Linear Issue <!-- Only if a Linear issue was fetched -->
   [<ISSUE-ID>](<issue url>) — <issue title>

   ## Summary
   <2-4 bullet points describing key changes>

   ## Test plan
   <Bulleted checklist of how to verify the changes>
   ```

   Omit the `## Linear Issue` section entirely if no Linear issue was detected.

8. **Create PR**:
   - Use `gh pr create` with a HEREDOC for the body
   - Add `--draft` flag if requested
   - Set `--base` to the specified base branch

9. **Output**:
   - Display the PR URL

### Important Rules

- Use Traditional Chinese (zh-TW) if all commit messages are in Chinese; otherwise use English
- Never fabricate or guess commit details — only use actual git history
- The summary must reflect ALL commits on the branch, not just the most recent one
- Do not add AI attribution or "Generated with" lines to the PR body
