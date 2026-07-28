---
name: pr-create
description: Push current branch and create a GitHub pull request with smart defaults
argument-hint: '[--base main] [--draft] [--title "title"]'
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git push:*), Bash(git rev-parse:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(pbcopy), Bash(mv *), Bash(date *), Read, AskUserQuestion, mcp__Linear*__get_issue, mcp__Linear*__save_issue, mcp__Linear*__save_comment, mcp__Linear*__list_issue_statuses
model: claude-sonnet-4-6
disable-model-invocation: true
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
   - Check if the branch name contains a Linear issue ID — a segment matching 2-5 letters, a hyphen, then digits. Match case-insensitively.
   - If found, uppercase it (e.g., `<issue-id>` → `<ISSUE-ID>`) and call `mcp__Linear*__get_issue` to fetch the issue's `title`, `identifier`, `url`, and current `status`.
   - If no issue ID is found in the branch name, or the fetch fails, skip this step and proceed without Linear context.

3. **Safety Checks**:
   - If there are uncommitted changes, warn the user and ask whether to proceed
   - If on `main` or `master`, refuse to create PR from the base branch
   - If no commits ahead of base, inform user there's nothing to PR

4. **Push if Needed**:
   - If branch has no upstream or is ahead of remote, push with `-u origin <branch>`
   - If `--no-push` is set, skip this step

5. **Linear Sync** (only if a Linear issue was detected in step 2):

   The issue ID comes from the branch (step 2) — there is no `.linear.md` mirror to read.

   **a. Flush queued progress.** If `.claude/recent-work/linear-sync-queue.md` exists and is non-empty, drain it per the **linear-sync** rule: claim it (`mv` to `linear-sync-queue.flushing.md`), merge its entries into one concise comment, post it to the issue with `mcp__Linear*__save_comment`, then delete the temp file. If the post fails, restore the queue file and warn the user. Skip silently if the queue is absent.

   **b. Move the issue to In Review.** Using the `status` from step 2 (or `mcp__Linear*__list_issue_statuses` for the issue's team), if the issue is not already in a review or completed state, set it to the team's review-stage status (e.g. `In Review`) via `mcp__Linear*__save_issue` (`id` + `state`). If no such status exists or the call fails, warn once and continue.

   Do **not** edit titles/descriptions or guess other status transitions here — opening the PR is a single, deterministic lifecycle moment. **MCP unavailable:** warn ("Linear MCP unavailable — sync skipped") and proceed. Never block PR creation on Linear sync.

6. **Analyze Changes**:
   - Review ALL commits on the branch (`git log <base>..HEAD`), not just the latest
   - Review the full diff (`git diff <base>...HEAD`) to understand scope
   - Determine change type: feature, fix, refactor, docs, chore, etc.

7. **Generate PR Content**:
   - **Title**: Short (under 70 chars), prefixed with type.
     - If `--title` provided, use that instead (skip all generation below)
     - If a Linear issue was fetched: `<type>(<ISSUE-ID>): <Linear issue title>`
       - Example: `feat(<ISSUE-ID>): <issue title>`
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
