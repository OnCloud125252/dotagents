# GitHub CLI Gotchas

- **`gh api repos/X/Y/compare/A...B`** — `status` is from **B's perspective**: `ahead` = B has commits A lacks (A doesn't contain B), `behind` = B is behind A (A contains B), `identical` = same. Binary-search release tags with `gh api repos/X/Y/compare/$TAG...$SHA --jq .status` to find which version first includes a commit.
- **`gh search prs --state`** only accepts `open|closed`. Use `--merged` (boolean flag) for merged state.
- **`gh search prs --json mergedAt`** is invalid (`Unknown JSON field: mergedAt`) — there is no merged-at field. Filter with the `--merged` flag and read `closedAt` instead.
- **PR-that-closed-an-issue**: `gh issue view N --json closedByPullRequestsReferences` returns linked PR numbers; faster than re-searching.
- **`gh pr edit <n> --add-reviewer <id>`** fails with "Could not resolve user" when `<id>` is a claude-peers session ID (e.g. `4709snyd`) — those are NOT GitHub logins. Cross-session peer review runs over the peer network (a peer reads the PR and reports back), then you merge on sign-off; it never touches GitHub's reviewer-request field. Pass a real GitHub username to `--add-reviewer`.
