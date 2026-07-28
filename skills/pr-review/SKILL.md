---
name: pr-review
description: |
  Fetch a PR into a temporary worktree, run CI checks (tests, lint, type-check),
  invoke /code-review, and present an interactive summary with inline review posting.
  Use this for an external PR (by number or URL); for your current working diff,
  run /code-review directly.
argument-hint: [<PR_number> | <PR_url>]
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(npm *)
  - Bash(pnpm *)
  - Bash(bun *)
  - Bash(python *)
  - Bash(go *)
  - Bash(cargo *)
  - Bash(make *)
  - Bash(mkdir *)
  - Bash(trash *)
  - Read
  - Glob
  - Grep
  - Skill
  - Agent
disable-model-invocation: true
---

# Review Pull Request

Review a GitHub pull request by checking it out in a temporary worktree, running CI checks, performing code review, and presenting an interactive summary. If the user chooses to post, leave **inline review comments** on the PR by default.

**Announce at start:** "Reviewing PR..."

## Step 1: Parse Argument & Detect PR

### 1a. Parse the argument

| Input format | Example | Action |
|---|---|---|
| Empty (no argument) | — | Auto-detect PR for current branch |
| Plain integer | `123` | Look up PR by number |
| PR URL | `https://github.com/owner/repo/pull/123` | Extract owner, repo, and number from URL |

**If no argument is provided:**

```bash
gh pr view --json number,headRefName,baseRefName,state,isDraft,url
```

If this fails, report: "No open PR found for the current branch. Pass a PR number or URL." and stop.

**If a plain integer is provided:**

```bash
gh pr view <N> --json number,headRefName,baseRefName,state,isDraft,url
```

**If a URL is provided** (matches `github.com/<owner>/<repo>/pull/<number>`):

Extract `OWNER`, `REPO`, `PR_NUMBER` from the URL:

```bash
gh pr view <PR_NUMBER> --repo <OWNER>/<REPO> --json number,headRefName,baseRefName,state,isDraft,url
```

### 1b. Detect the repository

If `OWNER/REPO` was not already extracted from a URL:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

### 1c. Store variables

Extract and store:

- `PR_NUMBER` — the PR number
- `PR_BRANCH` — the head branch name (`headRefName`)
- `BASE_BRANCH` — the base branch name (`baseRefName`)
- `PR_STATE` — open, closed, or merged
- `PR_URL` — the full PR URL
- `OWNER/REPO` — the repository identifier

### 1d. Eligibility check

- If `PR_STATE` is `CLOSED` or `MERGED`, warn the user and ask whether to continue reviewing a closed/merged PR.
- If `isDraft` is `true`, note this is a draft PR but proceed.

## Step 2: Create Temporary Worktree

### 2a. Determine worktree base directory

Priority order:

1. Check CLAUDE.md for a worktree directory preference (e.g., `.claude/worktrees`)
2. Check if `.claude/worktrees`, `.worktrees`, or `worktrees` already exists
3. Default to `.claude/worktrees`

Ensure the directory exists: `mkdir -p <worktree-base>`

### 2b. Derive worktree directory name

Use the pattern: `pr-review-<PR_NUMBER>` (e.g., `pr-review-42`).

If that path already exists (stale from a prior interrupted run), append `-2`, `-3`, etc.

### 2c. Fetch and create the worktree

```bash
git fetch origin <PR_BRANCH>
git worktree add <worktree-path> origin/<PR_BRANCH>
```

### 2d. Verify

```bash
cd <worktree-path> && git log --oneline -3 && pwd
```

Report: "Worktree created at `<worktree-path>`"

## Step 3: Run CI Checks (inside worktree)

Spawn an Agent to discover and run CI checks inside `<worktree-path>`. The agent should:

### 3a. Discover available checks

Probe in order (check all that apply, not just the first match):

| File / Condition | Commands to run |
|---|---|
| `package.json` with `scripts.test` | `npm test` (or `pnpm test` / `bun test` depending on lock file) |
| `package.json` with `scripts.lint` | `npm run lint` |
| `package.json` with `scripts.typecheck` or `scripts.type-check` | `npm run typecheck` or `npm run type-check` |
| `package.json` with `scripts.check` | `npm run check` |
| `Makefile` with `test` target | `make test` |
| `Makefile` with `lint` target | `make lint` |
| `go.mod` exists | `go test ./...` |
| `Cargo.toml` exists | `cargo test` |
| `pyproject.toml` exists | `python -m pytest` |

**Lock file detection** for choosing the package manager:

- `bun.lockb` or `bun.lock` → `bun`
- `pnpm-lock.yaml` → `pnpm`
- `yarn.lock` → `yarn`
- `package-lock.json` or none → `npm`

### 3b. Install dependencies if needed

If a lock file exists but `node_modules` is missing (or equivalent for other ecosystems), install dependencies first using the detected package manager.

### 3c. Run checks sequentially

Run each discovered check **sequentially** (parallel runs risk port/file conflicts). Set a 5-minute timeout per command.

For each check, capture:

- Command name (e.g., `npm test`)
- Exit code (0 = pass, non-zero = fail)
- Output (stdout + stderr, truncated to 100 lines if longer)
- Duration

If no checks are discovered, report "No CI checks found in this project" and continue.

### 3d. Return structured results

The agent should return a structured list of CI results.

## Step 4: Code Review via `/code-review` Skill

Invoke the `/code-review` skill using the Skill tool:

```
Skill(skill: "code-review", args: "<PR_NUMBER>")
```

This runs the full code-review pipeline: eligibility check, parallel review agents, confidence scoring, and finding filtering.

**Important:** After the skill completes, collect and retain any findings it reports. These will be combined with CI results in Step 6.

## Step 5: Cleanup Worktree

Remove the temporary worktree:

```bash
git worktree remove <worktree-path>
```

If this fails (e.g., test artifacts or generated files block removal):

```bash
git worktree remove --force <worktree-path>
```

Report: "Worktree cleaned up."

## Step 6: Assemble Structured Summary

Combine CI results (from Step 3) and code review findings (from Step 4) into a **labeled interactive summary**. Assign each item a unique letter label starting from A.

Display format:

```
========================================
  PR #<N> Review Results
========================================

## CI Results

  A) ✅ npm test             — PASS (12.3s)
  B) ❌ npm run lint         — FAIL (2.1s)
  C) ✅ npm run typecheck    — PASS (8.7s)

## Code Review Findings

  D) 🔴 path/to/file.ts:L42 — Potential null dereference
     when `user` is undefined, `.name` access will throw

  E) 🟡 path/to/other.ts:L17 — CLAUDE.md violation
     Missing error handling (CLAUDE.md: "always handle async errors")

  F) 🔴 path/to/util.ts:L88 — Regression risk
     Reverts fix from PR #91 (off-by-one in pagination)

========================================
```

Severity indicators:

- 🔴 High confidence / critical issue
- 🟡 Medium confidence / style or guideline issue
- ✅ Pass / no issue
- ❌ Fail

If CI found no checks, show "No CI checks discovered" instead of the CI section.
If code review found no issues, show "No code review issues found" instead of the findings section.

## Step 7: Ask User What To Do

After presenting the summary, ask the user what they want to do next:

- **Post all findings as inline review** (default) — post every code review finding as an inline review comment on the PR
- **Post selected findings only** — user specifies labels (e.g., "D, F") to include in the review
- **Skip posting** — just keep the summary displayed, don't post anything to the PR

Wait for user input before proceeding.

## Step 8: Post Inline Review (if user chose to post)

Use the GitHub Pull Request Review API to create **inline review comments** attached to specific files and lines in the PR diff.

### 8a. Build the review payload

For each selected code review finding, construct a comment object:

- `path` — the file path relative to the repo root
- `line` — the line number in the diff
- `side` — `RIGHT` (the PR's version of the file)
- `body` — the finding description

For CI failures (which don't map to specific files), include them in the top-level review `body` summary.

### 8b. Determine review event type

- If any finding is 🔴 (critical) → use `REQUEST_CHANGES`
- If only 🟡 findings → use `COMMENT`
- If no code review findings (only CI results) → use `COMMENT`

### 8c. Post the review

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/reviews \
  --method POST \
  -f event="<EVENT_TYPE>" \
  -f body="<CI summary and overall notes>" \
  --input <json-file-with-comments>
```

The JSON input for inline comments should follow this structure:

```json
{
  "event": "COMMENT",
  "body": "## Review Summary\n\n...",
  "comments": [
    {
      "path": "src/file.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "Potential null dereference: ..."
    }
  ]
}
```

### 8d. Report result

Display: "Review posted on PR #<N> — <PR_URL>"

If the API call fails, print the full review content to stdout and suggest the user post it manually.

## Error Handling

| Situation | Handling |
|---|---|
| No PR found for current branch | Report clearly and stop |
| `git fetch` fails (no network or branch deleted) | Abort with error |
| Worktree path already exists | Append `-2`, `-3` suffix |
| No CI checks discovered | Report "No CI checks discovered", still run code review |
| Test/lint exceeds 5-min timeout | Kill the process, mark as TIMEOUT in results |
| `/code-review` finds no issues | Report "No code review issues found" |
| `gh api` review post fails | Print review to stdout, suggest manual posting |
| Closed/merged PR | Warn, ask user before proceeding |

## Do NOT

- Push any commits to the PR branch
- Modify any files in the main worktree
- Run `git worktree remove` on anything other than the `pr-review-*` worktree you created
- Skip the user confirmation step — always ask before posting
