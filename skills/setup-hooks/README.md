# setup-hooks — design notes

This is the human-facing design rationale; agents should read `SKILL.md`
instead.

## Goal

Take the `.githooks/` + `scripts/setup-hooks.sh` pattern proven out in an
internal Go backend repo and make it reusable across any repo, not just Go
projects.

The original work proved out:

- `core.hooksPath = .githooks` (committed scripts) instead of `.git/hooks`
  (gitignored) so hooks travel with the repo and aren't lost on clone
- A separate setup script that **aborts** if any required tool is missing
  rather than silently degrading
- A Claude Code `PreToolUse` hook that runs the setup script automatically
  on the first Bash call after clone, gated by a `.claude/.githooks-initialized`
  marker
- gitleaks on **staged** content at commit time and on the **commit range**
  at push time (not on the working tree)
- Auto-format with re-staging that touches only the files that were
  already staged

The Go-specific bits (`gofmt`, `golangci-lint`, `make grpc`, `cmd/<svc>`
build target derivation) don't generalize. Everything else does.

## Why three stacks (not one configurable hook)

A single "smart" hook script that runs `bun run check` if `bun.lock` is
present, `pnpm run check` if `pnpm-lock.yaml` is present, etc. is tempting
but ends up:

- Opaque (you have to read 200 lines to see what'll fire)
- Slower (every detection probe runs every commit)
- Harder to add a new stack (one giant if-else)
- Hostile to copy-edit ("just add a step before lint" becomes a 4-way merge)

Concrete templates per stack are easier to read, faster to run, and easier
to fork when a project's needs diverge.

## Why optional gitleaks

`gitleaks` is excellent but requires either a `.gitleaks.toml` config or
explicit allowlists, and the default rules false-positive on common
test fixtures. Forcing it on every repo adds friction. The convention is:

- If the repo has `.gitleaks.toml`, gitleaks is **required** at hook setup
  and runs on every commit/push
- If the file is absent, gitleaks is silently skipped (and not listed as
  a required tool)

This matches `Lazco-Studio/api` (has `.gitleaks.toml`, runs gitleaks) and
`Lazco-Studio/cloud` (no config, skips it).

## Why no "shared/cli-output.sh" sourcing at runtime

Hooks have to work after a fresh `git clone`, before any setup runs. If
hooks `source ~/.agents/skills/setup-hooks/templates/shared/cli-output.sh`,
they fail on machines that don't have this skill installed. Inlining the
~50 lines of color/log helpers in every hook is the lesser evil — they
don't change often, and the duplication keeps the hooks self-contained.

The `shared/cli-output.sh` snippet in this directory is a **reference**
copy used to keep the inlined versions consistent across templates.

## What's NOT in v1

- **Husky / lefthook / pre-commit (the framework)** — the goal is *fewer*
  dependencies, not more. Plain `core.hooksPath` is enough.
- **post-merge for JS stacks** — `bun install` / `pnpm install` after a
  pull is useful but not always wanted (some teams pin lockfiles
  differently). Skipped to avoid surprises; can be added later.
- **Commit message lint** (`commit-msg` hook) — out of scope; covered by
  the `commit` skill / Conventional Commits convention at PR review time.
- **A configurable per-stack `.setup-hooks.json`** — over-engineered.
  If a repo wants to diverge, it can fork the generated `.githooks/`
  files, which are checked in.
