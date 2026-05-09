---
name: setup-hooks
description: |
  Scaffold a stack-appropriate git-hooks pipeline (.githooks/ + scripts/setup-hooks.sh)
  into the current repo. Detects the stack automatically — Go, bun+biome, or pnpm+biome —
  and falls back to an interactive picker. Patches the repo's .claude/settings.json to
  auto-run the init script on Claude Code's first Bash call.

  Use when the user asks to "set up git hooks", "/setup-hooks", "scaffold hooks", or
  after creating a new repo that should follow the same hook conventions as
  Zeabur/backend (gitleaks + format/lint auto-fix on commit, full lint + build on push).

  Re-run safe: detects existing .githooks/ and core.hooksPath, shows a diff, and asks
  the user before overwriting.
---

# setup-hooks

This skill drops a tailored set of git hooks into any repo. The pipeline mirrors the
`Zeabur/backend` PLA-1360 design — staged-only secret scanning + auto-format on
commit, full lint + build on push — but adapts the actual commands to whichever
toolchain the repo uses.

## Supported stacks (v1)

| Stack         | Detected by                          | Pre-commit                       | Pre-push                                   |
|---------------|--------------------------------------|----------------------------------|--------------------------------------------|
| `go`          | `go.mod`                             | `gitleaks` + `gofmt -w` staged   | `gitleaks` + proto/gql regen + `golangci-lint --fix` + `go build` affected `cmd/*` |
| `bun-biome`   | `bun.lock` + `biome.json`            | `gitleaks?` + `biome check --write --staged` | `gitleaks?` + `bun run check` + `bunx tsc --noEmit` + `bun test?` |
| `pnpm-biome`  | `pnpm-lock.yaml` + `biome.json`      | `gitleaks?` + `biome check --write --staged` | `gitleaks?` + `pnpm run check` + `pnpm exec tsc --noEmit` + `pnpm test?` |

`gitleaks?` and `bun test?` mean optional — included only if `.gitleaks.toml` /
the `test` script exist in the repo.

## How the command runs

The user invokes `/setup-hooks`. The command (see `~/.agents/commands/setup-hooks.md`)
follows this flow:

1. **Detect stack** — runs `~/.agents/skills/setup-hooks/detect.sh` from the repo root.
   Result is `<stack>\t<reason>`. If `unknown`, ask the user to pick from
   the supported list (or abort).
2. **Confirm with user** — show detected stack + reason; offer
   `confirm / pick different / abort` via `AskUserQuestion`.
3. **Inspect existing setup** — if any of these are already present, summarize and
   ask what to do (`keep / overwrite / merge per-file`):
   - `core.hooksPath` already set
   - `.githooks/` directory already populated
   - `scripts/setup-hooks.sh` already exists
   - `.claude/settings.json` already has `PreToolUse` hook calling `setup-hooks.sh`
4. **Copy templates** — for the chosen stack, copy every file from
   `~/.agents/skills/setup-hooks/templates/<stack>/` into the repo:
   - `pre-commit`, `pre-push` (and `post-merge` for Go) → `<repo>/.githooks/`
   - `setup-hooks.sh` → `<repo>/scripts/setup-hooks.sh`
   - `chmod +x` everything copied
5. **Patch `.claude/settings.json`** — create the file if missing, otherwise
   merge (do not clobber). Add:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         { "matcher": "Bash", "hooks": [
           { "type": "command",
             "command": "test -f .claude/.githooks-initialized || ./scripts/setup-hooks.sh </dev/null >&2" }
         ]}
       ],
       "PostToolUse": [
         { "matcher": "Write|Edit", "hooks": [
           { "type": "command", "command": "<stack-specific formatter command>" }
         ]}
       ]
     }
   }
   ```
   Stack-specific PostToolUse formatter:
   - `go`: `jq -r '.tool_input.file_path // .tool_response.filePath' | { read -r f; case "$f" in *.go) gofmt -w "$f" ;; esac; } 2>/dev/null || true`
   - `bun-biome`: `jq -r '.tool_input.file_path // .tool_response.filePath' | { read -r f; case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.jsonc) bunx --bun biome format --write "$f" ;; esac; } 2>/dev/null || true`
   - `pnpm-biome`: `jq -r '.tool_input.file_path // .tool_response.filePath' | { read -r f; case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.jsonc) pnpm exec biome format --write "$f" ;; esac; } 2>/dev/null || true`
6. **Run `./scripts/setup-hooks.sh` once** — this verifies tools are installed,
   sets `core.hooksPath`, makes hooks executable, and writes
   `.claude/.githooks-initialized`. If it aborts on missing tools, surface
   the install hints to the user verbatim.
7. **Print summary** — list files added/skipped, what to commit, and which
   tools the user needs.

## Philosophy (from PLA-1360)

- **No skip-on-missing**: required tools must be installed; the script aborts.
- **Non-destructive merge**: never clobber an existing `.claude/settings.json` —
  only add the `PreToolUse`/`PostToolUse` entries for the marker check.
- **Self-contained hooks**: every generated hook script inlines its own CLI
  helpers. The `templates/shared/cli-output.sh` snippet is a reference for
  consistency, **not** sourced at runtime.
- **Re-stage only originally-staged files**: gofmt/biome `--write` runs on
  staged files; only those files get re-added so unrelated unstaged work
  is never swept into a commit.

## Files

```
~/.agents/skills/setup-hooks/
├── SKILL.md
├── README.md                                  # design notes for human readers
├── detect.sh                                  # stack detection
└── templates/
    ├── shared/cli-output.sh                   # reference snippet (not sourced at runtime)
    ├── go/{pre-commit, pre-push, post-merge, setup-hooks.sh}
    ├── bun-biome/{pre-commit, pre-push, setup-hooks.sh}
    └── pnpm-biome/{pre-commit, pre-push, setup-hooks.sh}
```

## Adding a new stack

1. Create `templates/<stack>/` with `pre-commit`, `pre-push`, optionally
   `post-merge`, and `setup-hooks.sh`.
2. Update `detect.sh` with the detection rule.
3. Update the table at the top of this file.
4. Update the PostToolUse formatter mapping in step 5 of the command flow.
