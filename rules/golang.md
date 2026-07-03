---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go + Worktree Gotchas

- **LSP follows a single workspace root.** When working in a worktree under `.claude/worktrees/`, the LSP rooted in another worktree throws false `use of internal package not allowed` / `current file is not included in a workspace module` diagnostics on valid `internal/` imports. **Trust `go build`, not the LSP**, when both disagree.
- **`sed -i '' 'N,Md' file.go`** leaves stray double blank lines that lint flags as `goimports` / `File is not properly formatted`. Run `gofmt -w file.go` immediately after any sed-based deletion.
