---
name: Resolve PR Reviews
description: |
  Fetch unresolved PR review threads, fix the issues, reply with commit SHA,
  resolve threads via GraphQL, and post a summary comment. Use when asked to
  resolve or address PR review feedback.
argument-hint: <PR_LINK_OR_NUMBER_OR_COMMENT_LINK>
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
---

# Resolve PR Review Threads

Automatically fetch unresolved review threads on a GitHub PR, apply fixes, reply with the commit SHA, resolve threads via GraphQL, and post a summary comment.

Supports two modes:
- **All comments** — pass a PR number or PR URL → addresses every unresolved thread.
- **Single comment** — pass a review comment URL → addresses only that one thread.

## Step 1: Setup — Parse the Argument

The user provides one of the following as the argument:

| Input format | Example | Mode |
|---|---|---|
| PR number | `123` | All unresolved threads |
| PR URL | `https://github.com/owner/repo/pull/123` | All unresolved threads |
| Comment URL | `https://github.com/owner/repo/pull/123#discussion_r1234567890` | Single thread only |

### 1a. Parse the argument

- **Plain integer** → `PR_NUMBER = <arg>`, `COMMENT_ID = null`, mode = `all`.
- **PR URL** (matches `github.com/<owner>/<repo>/pull/<number>`) → extract `OWNER`, `REPO`, `PR_NUMBER` from the URL, `COMMENT_ID = null`, mode = `all`.
- **Comment URL** (matches `github.com/<owner>/<repo>/pull/<number>#discussion_r<id>`) → extract `OWNER`, `REPO`, `PR_NUMBER`, and `COMMENT_ID = <id>` (the integer after `discussion_r`), mode = `single`.

If the argument does not match any of the above, ask the user for a valid PR number, PR URL, or comment URL.

### 1b. Detect the repository

If `OWNER/REPO` was not already extracted from a URL:
```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```
→ store as `OWNER/REPO`.

### 1c. Confirm the PR and check out the branch

```bash
gh pr view <PR_NUMBER> --repo <OWNER>/<REPO> --json state,headRefName -q '.state + " " + .headRefName'
```

Check out the PR branch and pull latest:
```bash
git fetch origin <BRANCH>
git checkout <BRANCH>
git pull origin <BRANCH>
```

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

1. Read the file at `path` around `line` (with **generous** surrounding context — at least ±30 lines).
2. Study the `diffHunk` and reviewer's `body` to understand what is requested.
3. **Verify whether the issue actually needs fixing.** Before classifying, critically evaluate the reviewer's feedback against the actual code:
   - Does the reviewer's concern apply to the current state of the code, or was it based on an outdated diff?
   - Is the suggested change actually an improvement, or would it introduce a regression, break existing behavior, or conflict with the codebase's conventions?
   - Is the reviewer factually correct? (e.g., does the "bug" they point out actually exist? Is the API they reference real?)
   - Could the reviewer have misread the code or missed surrounding context that addresses their concern?
   - If the review suggests a refactor or style change, does it align with the project's established patterns?
4. Classify the thread into one of:
   - **Actionable — Valid** — the reviewer's feedback is correct and the code genuinely needs the requested change → plan the fix.
   - **Actionable — Disagree** — the reviewer requests a change, but after verification the current code is correct or the suggestion would cause harm → do NOT fix. Flag for the user to respond manually with a rationale.
   - **Question/Informational** — reviewer asks a question or leaves a note → do NOT auto-resolve. Flag for the user to respond manually.
5. Group valid actionable threads by file for cleaner commits.

Present the plan to the user before proceeding. List each thread with:
- File and line
- Reviewer comment (abbreviated)
- **Verdict**: one of `Will fix`, `Disagree — needs manual response`, or `Question — needs manual response`
- For `Will fix` — the proposed fix
- For `Disagree` — a brief explanation of why the current code is correct

**Wait for user approval before applying any fixes.** The user may override any verdict.

## Step 4: Apply Fixes, Commit, Push

1. Edit the files to address all actionable threads.
2. **Verify** each change by re-reading the modified files.
3. Stage specific files (never `git add -A`):
   ```bash
   git add <file1> <file2> ...
   ```
4. Commit with a descriptive message referencing the PR:
   ```bash
   git commit -m "fix: address review feedback from PR #<PR_NUMBER>"
   ```
5. Push to the remote:
   ```bash
   git push origin <BRANCH>
   ```
6. Record the commit SHA:
   ```bash
   git rev-parse --short HEAD
   ```

## Step 5: Reply & Resolve Each Thread

Process threads **sequentially** to avoid GitHub API race conditions.

For each **actionable** thread that was fixed:

### 5a. Reply via REST

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<DB_ID>/replies \
  -f body="Fixed in <SHORT_SHA>."
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
- Were skipped (questions/informational)
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
| 2 | `path/to/other` | L17 | Fixed per reviewer request | `abc1234` |
| ... | | | | |

**Skipped threads** (require manual response):
- Thread at `path/file:L10` — reviewer asked a question

All actionable review threads have been resolved.
EOF
)"
```

## Error Handling

- **API rate limit** → wait 60 seconds, retry once.
- **Push failure** → run `git pull --rebase origin <BRANCH>`, then retry push.
- **GraphQL mutation error** → log the error, continue with remaining threads, report all failures at the end.
- **Permission error** → inform the user they may lack write access or the thread may already be resolved.
- **Outdated thread** → still attempt to resolve; note in summary if the diff context has changed.
