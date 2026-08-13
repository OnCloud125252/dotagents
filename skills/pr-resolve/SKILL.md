---
name: pr-resolve
description: |
  Fetch unresolved PR review threads, fix the issues, reply with commit SHA,
  resolve threads via GraphQL, and post a summary comment. Use when asked to
  resolve or address PR review feedback. If no argument is given, auto-detects
  the PR for the current branch.
argument-hint: "[PR_LINK_OR_NUMBER_OR_COMMENT_LINK]"
disable-model-invocation: true
---

# Resolve PR Review Threads

Automatically fetch unresolved review threads on a GitHub PR, apply fixes, reply with the commit SHA, resolve threads via GraphQL, and post a summary comment.

Supports three modes:

- **Auto-detect** — pass no argument → detects the PR for the current branch and addresses every unresolved thread.
- **All comments** — pass a PR number or PR URL → addresses every unresolved thread.
- **Single comment** — pass a review comment URL → addresses only that one thread.

## Step 1: Setup — Parse the Argument

The user provides one of the following as the argument (or omits it):

| Input format | Example | Mode |
|---|---|---|
| _(none)_ | (no argument) | Auto-detect PR for current branch — all unresolved threads |
| PR number | `123` | All unresolved threads |
| PR URL | `https://github.com/owner/repo/pull/123` | All unresolved threads |
| Comment URL | `https://github.com/owner/repo/pull/123#discussion_r1234567890` | Single thread only |

### 1a. Parse the argument

- **No argument provided** → auto-detect the PR for the current branch:

  ```bash
  gh pr view --json number -q '.number'
  ```

  - On success → set `PR_NUMBER = <output>`, leave `OWNER/REPO` unset (Step 1b will fill them in), `COMMENT_ID = null`, mode = `all`.
  - On non-zero exit (no PR found for current branch) → inform the user there is no PR for the current branch and ask them to provide a PR number, PR URL, or comment URL. Do not guess.
- **Plain integer** → `PR_NUMBER = <arg>`, `COMMENT_ID = null`, mode = `all`.
- **PR URL** (matches `github.com/<owner>/<repo>/pull/<number>`) → extract `OWNER`, `REPO`, `PR_NUMBER` from the URL, `COMMENT_ID = null`, mode = `all`.
- **Comment URL** (matches `github.com/<owner>/<repo>/pull/<number>#discussion_r<id>`) → extract `OWNER`, `REPO`, `PR_NUMBER`, and `COMMENT_ID = <id>` (the integer after `discussion_r`), mode = `single`.

If a non-empty argument does not match any of the above, ask the user for a valid PR number, PR URL, or comment URL.

### 1b. Detect the repository

If `OWNER/REPO` was not already extracted from a URL:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

→ store as `OWNER/REPO`.

### 1c. Confirm the PR and determine the branch

```bash
gh pr view <PR_NUMBER> --repo <OWNER>/<REPO> --json state,headRefName -q '.state + " " + .headRefName'
```

Check whether the current branch already matches the PR branch:

```bash
git rev-parse --abbrev-ref HEAD
```

**If the current branch matches `<BRANCH>`** — fetch and pull latest in place:

```bash
git fetch origin <BRANCH>
git pull origin <BRANCH>
```

Set `WORKTREE_PATH = "."` and `WORKTREE_CREATED = false`.

**If the current branch does NOT match `<BRANCH>`** — create a worktree under `.claude/worktrees/` instead of checking out:

```bash
git fetch origin <BRANCH>
git worktree add .claude/worktrees/<BRANCH> <BRANCH>
git -C .claude/worktrees/<BRANCH> pull origin <BRANCH>
```

Set `WORKTREE_PATH = ".claude/worktrees/<BRANCH>"` and `WORKTREE_CREATED = true`.

All subsequent `git` operations (stage, commit, push, rev-parse) **must** use `git -C "$WORKTREE_PATH"` so they run against the correct working tree. All file reads and edits must use paths prefixed with `$WORKTREE_PATH/` (e.g., `$WORKTREE_PATH/src/file.go`).

## Step 2: Fetch Threads

Query all review threads via GraphQL:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            diffSide
            comments(first: 10) {
              nodes {
                databaseId
                body
                author { login }
                diffHunk
              }
            }
          }
        }
      }
    }
  }
' -F owner="<OWNER>" -F repo="<REPO>" -F pr=<PR_NUMBER>
```

### Filtering

- **Mode `all`** — filter to threads where `isResolved: false`.
- **Mode `single`** — find the thread whose comments contain a `databaseId` matching `COMMENT_ID`. If that thread is already resolved, inform the user and exit. If no thread matches, inform the user the comment was not found.

For each matching thread extract:

- `threadId` — the node ID (for GraphQL `resolveReviewThread`)
- `databaseId` — the first comment's integer ID (for REST reply)
- `body` — the reviewer's comment text
- `path` — the file path
- `line` — the line number
- `diffHunk` — surrounding diff context

**Exit early** if zero matching unresolved threads remain. Inform the user.

## Step 3: Analyze, Verify & Plan Fixes

For each unresolved thread:

1. Read the file at `$WORKTREE_PATH/<path>` around `line` (with **generous** surrounding context — at least ±30 lines).
2. Study the `diffHunk` and reviewer's `body` to understand what is requested.
3. **Verify whether the issue actually needs fixing.** Before classifying, critically evaluate the reviewer's feedback against the actual code:
   - Does the reviewer's concern apply to the current state of the code, or was it based on an outdated diff?
   - Is the suggested change actually an improvement, or would it introduce a regression, break existing behavior, or conflict with the codebase's conventions?
   - Is the reviewer factually correct? (e.g., does the "bug" they point out actually exist? Is the API they reference real?)
   - Could the reviewer have misread the code or missed surrounding context that addresses their concern?
   - If the review suggests a refactor or style change, does it align with the project's established patterns?
4. Classify the thread into one of:
   - **Actionable — Valid** — the reviewer's feedback is correct and the code genuinely needs the requested change → plan the fix.
   - **Actionable — Disagree** — the reviewer requests a change, but after verification the current code is correct or the suggestion would cause harm → do NOT fix. Draft a rationale reply explaining why the current code is correct.
   - **Question/Informational** — reviewer asks a question or leaves a note → draft an answer or acknowledgement reply.
5. Group valid actionable threads by file for cleaner commits.

Present the plan to the user before proceeding. List each thread with:

- File and line
- Reviewer comment (abbreviated)
- **Verdict**: one of `Will fix`, `Disagree — will reply with rationale`, or `Question — will reply with answer`
- For `Will fix` — the proposed fix
- For `Disagree` — the draft rationale to be posted as a reply
- For `Question` — the draft answer to be posted as a reply

**Wait for user approval before applying any changes.** The user may override any verdict (e.g., change a "Disagree" to "Will fix", edit a draft reply, or skip a thread entirely).

## Step 4: Apply Fixes, Commit, Push

1. Edit the files to address all actionable threads. All file paths are relative to `$WORKTREE_PATH`.
2. **Verify** each change by re-reading the modified files at `$WORKTREE_PATH/<path>`.
3. Stage specific files (never `git add -A`):

   ```bash
   git -C "$WORKTREE_PATH" add <file1> <file2> ...
   ```

4. Commit with a descriptive message referencing the PR:

   ```bash
   git -C "$WORKTREE_PATH" commit -m "fix: address review feedback from PR #<PR_NUMBER>"
   ```

5. Push to the remote:

   ```bash
   git -C "$WORKTREE_PATH" push origin <BRANCH>
   ```

6. Record the commit SHA:

   ```bash
   git -C "$WORKTREE_PATH" rev-parse --short HEAD
   ```

## Step 5: Reply & Resolve Each Thread

Process threads **sequentially** to avoid GitHub API race conditions.

For **every** thread addressed in this run (fixed, disagreed, or answered):

### 5a. Reply via REST

Choose the reply body based on the thread's verdict:

- **Will fix** → `"Fixed in <SHORT_SHA>."`
- **Disagree** → the rationale explaining why the current code is correct (as approved by the user in Step 3)
- **Question** → the answer or acknowledgement (as approved by the user in Step 3)

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<DB_ID>/replies \
  -f body="<REPLY_BODY>"
```

### 5b. Resolve via GraphQL

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread { isResolved }
    }
  }
' -f threadId="<THREAD_NODE_ID>"
```

## Step 6: Verify

Re-fetch the review threads (same query as Step 2). Confirm all addressed threads show `isResolved: true`.

Report any threads that:

- Failed to resolve (log the error)
- Were explicitly skipped by the user during plan approval
- Remain unresolved for other reasons

## Step 7: Summary Comment

**Skip this step in `single` mode** — a summary comment is unnecessary for a single thread.

In `all` mode, post a summary comment on the PR:

```bash
gh pr comment <PR_NUMBER> -b "$(cat <<'EOF'
## Review Feedback Addressed

| # | File | Line | Action | Commit |
|---|------|------|--------|--------|
| 1 | `path/to/file` | L42 | Fixed per reviewer request | `abc1234` |
| 2 | `path/to/other` | L17 | Replied with rationale (disagree) | — |
| 3 | `path/to/other` | L25 | Replied with answer | — |
| ... | | | | |

**Skipped threads** (excluded by user during plan approval):
- Thread at `path/file:L10` — user chose to skip

All review threads have been addressed and resolved.
EOF
)"
```

## Step 8: Worktree Cleanup (if applicable)

**Skip this step if `WORKTREE_CREATED = false`.**

If a worktree was created in Step 1c, ask the user whether to remove it:

> "A worktree was created at `.claude/worktrees/<BRANCH>`. Would you like to remove it now that the review has been addressed?"

If the user confirms, remove the worktree:

```bash
git worktree remove .claude/worktrees/<BRANCH>
```

If the worktree has uncommitted changes that prevent removal, inform the user and suggest they check it manually.

## Error Handling

- **API rate limit** → wait 60 seconds, retry once.
- **Push failure** → run `git -C "$WORKTREE_PATH" pull origin <BRANCH>` (merge), then retry push.
- **GraphQL mutation error** → log the error, continue with remaining threads, report all failures at the end.
- **Permission error** → inform the user they may lack write access or the thread may already be resolved.
- **Outdated thread** → still attempt to resolve; note in summary if the diff context has changed.
- **Worktree already exists** → if `.claude/worktrees/<BRANCH>` already exists, use it as-is (do not re-add), `cd` into it, set `WORKTREE_PATH = "."` and `WORKTREE_CREATED = false` so cleanup is not offered automatically.
