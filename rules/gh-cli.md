# GitHub CLI Gotchas

- **`gh api repos/X/Y/compare/A...B`** — `status` is from **B's perspective**: `ahead` = B has commits A lacks (A doesn't contain B), `behind` = B is behind A (A contains B), `identical` = same. Binary-search release tags with `gh api repos/X/Y/compare/$TAG...$SHA --jq .status` to find which version first includes a commit.
- **`gh search prs --state`** only accepts `open|closed`. Use `--merged` (boolean flag) for merged state.
- **PR-that-closed-an-issue**: `gh issue view N --json closedByPullRequestsReferences` returns linked PR numbers; faster than re-searching.
