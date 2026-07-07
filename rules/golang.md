---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go + Worktree Gotchas

- **`sed -i '' 'N,Md' file.go`** leaves stray double blank lines that lint flags as `goimports` / `File is not properly formatted`. Run `gofmt -w file.go` immediately after any sed-based deletion.
