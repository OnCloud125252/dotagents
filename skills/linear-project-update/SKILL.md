---
name: linear-project-update
description: |
  Draft a Traditional Chinese project update for a Linear project by
  correlating its milestones and issues with recent git commits and
  GitHub PRs, then copy the markdown body to the clipboard via pbcopy.
argument-hint: "<linear_project_url | linear_project_slug | linear_project_id>"
disable-model-invocation: true
---

# Linear Project Update

Produce a project update for a Linear project and copy it to the clipboard. **Target language is Traditional Chinese (zh-TW)** unless the user overrides. The final clipboard contents are the markdown body only — health and date are metadata that get shown to the user to fill into Linear's UI fields, never into the body.

**Announce at start:** "Drafting project update for `$ARGUMENTS`..."

## Step 1: Parse the Argument

`$ARGUMENTS` may be any of:

| Input | Example | Action |
|---|---|---|
| Full URL | `https://linear.app/<org>/project/<name>-<id>/overview` | Extract the trailing ID segment after the last `-` |
| Slug with trailing ID | `new-lazco-cloud-website-5d06d0f086cd` | Take the trailing hex segment as the project ID |
| Bare ID | `5d06d0f086cd` or UUID | Use as-is |
| Project name | `New Lazco Cloud Website` | Resolve via `lazco_linear_list_projects` then pick the match |

If the argument is empty, ask the user for the project URL / ID before continuing.

## Step 2: Fetch Project Data via Linear MCP

Run these in parallel:

1. `lazco_linear_get_project` with the resolved ID → project metadata, milestones with `currentProgress` blocks, attached issues.
2. If milestones don't embed all issues, follow up with `lazco_linear_search_issues_by_identifier` for the missing ones to get states, assignees, labels, descriptions, and comments.

Record the authoritative progress number from `currentProgress` (e.g., `scopeCount: 12, completedIssueCount: 8, progress: 70.83`) — **quote Linear's number, don't recompute**. Note the next milestone's `targetDate`.

## Step 3: Gather Git + GitHub Context

In parallel:

- `git log --since="2 weeks ago" --pretty=format:"%h|%ad|%s" --date=short` — commits on current branch.
- `git log --oneline -n 40` — fallback / short view if the window is empty.
- `gh pr list --state all --limit 30 --search "created:>=<YYYY-MM-DD>" --json number,title,state,mergedAt,closedAt,author` — use a date 2 weeks back.
- `gh repo view --json nameWithOwner -q .nameWithOwner` — capture `OWNER/REPO` for PR references.

If the project's target date is >2 weeks away, widen the window accordingly. If the repo has no commits in the window, fall back to the most recent 40.

## Step 4: Correlate Commits, PRs, and Issues

Build an internal mapping before writing prose:

- Group commits by theme (auth, billing, collector, dashboard, PVE, admin, perf, etc.) — inspect prefixes like `feat(domain):`, `fix(domain):`, `perf:`.
- Match commits and PRs to Linear issues via branch names (`<prefix>/<issue-id>-...`), PR titles (`refactor(<ISSUE-ID>):`), and commit messages referencing `<ISSUE-ID>`.
- Classify each Linear issue by state: `Done` / `In Progress` / `Backlog` / `Todo`. Use state to slot it into one of the four body sections.

## Step 5: Compose the Draft

### Style rules — non-negotiable

1. **Language:** Traditional Chinese (zh-TW). Technical identifiers (`<ISSUE-ID>`, `owner/repo#N`, commit hashes, endpoint paths, config keys) stay in their original form.
2. **TL;DR is `# H1`** and is followed by a single `---` divider on its own line. Nothing else uses H1.
3. **PRs are always `owner/repo#N`** in backticks (e.g., `` `<owner>/<repo>#<N>` ``) — never bare `PR #<N>`. Use the `OWNER/REPO` captured in Step 3.
4. **Linear issue IDs need whitespace on both sides** when adjacent to CJK characters. Correct: `解決 <ISSUE-ID> 的問題`. Wrong: `解決<ISSUE-ID>的問題`. Full-width punctuation (`（`, `，`, `。`, `、`) counts as a boundary on its own, so `（<ISSUE-ID>）` is fine without extra padding.
5. **Commit hashes** go in backticks (e.g., `` `82340a3` ``).
6. **Health and date are metadata** — shown separately to the user, *never* included in the clipboard body.

### Body structure (in this order)

```markdown
# TL;DR

<2–4 sentences: milestone progress with Linear's own percentage, days of runway to next target date, biggest blocker + its fix path, next-milestone readiness.>

---

### 本週已上線
- **<主題>** — <一句話描述>（<相關 LAZ-XX、commit、PR 參照>）。
- ...

### 進行中
- **LAZ-XX — <標題>。** <根因或最新狀態 1–3 句。>
- ...

### 接下來（<下個里程碑名稱> 截止前）
- <具體待辦>。
- ...

### 風險與值得留意的項目
- **<風險>** — <原因 + 建議行動>。
- ...
```

Omit a section entirely if it's empty — don't write "無" placeholders.

## Step 6: Show Metadata to the User

Before copying, present a short metadata block so the user can fill in Linear's form fields:

```markdown
### 元資料（請在 Linear UI 的欄位填入）
- **Health：** <🟢 On track | 🟡 At risk | 🔴 Off track>
- **Date：** <YYYY-MM-DD — today's date>
```

Choose health based on: milestone progress vs. time remaining, presence/absence of a clear unblock path for in-progress blockers, and scope definition for upcoming milestones.

## Step 7: Copy Body to Clipboard

Copy **only the body** (starting from `# TL;DR`, including the `---` divider and all section headings). Use a single-quoted heredoc to avoid shell expansion of backticks, hashes, and CJK content:

```bash
cat <<'EOF' | pbcopy
# TL;DR

<...draft body...>
EOF
pbpaste | wc -c
```

Report the character count back to the user as confirmation.

## Step 8: Final Report

Tell the user:

1. The metadata values to fill in (health + date).
2. That the body is on the clipboard — ready to paste into Linear's `Project → Updates → New update` dialog.
3. That the Linear MCP here doesn't expose `projectUpdateCreate`, so manual paste is required.

Offer to:

- Tighten, reframe (e.g., risk-first), or re-translate to another language.
- Adjust the time window (e.g., "only commits since last Friday").
- Drop or add a section.

## Do NOT

- Include health or date lines inside the clipboard content.
- Write bare `PR #N` — always namespace to `owner/repo#N`.
- Omit the space between CJK characters and `LAZ-XX`.
- Recompute milestone progress manually — use Linear's `currentProgress.progress`.
- Post the update via any MCP tool — current surface lacks that capability.
- Invent issues, commits, or PRs that aren't in the fetched data.
