# Status line

> Reference for the Claude Code status line used in this project.

## How it works in this project

This project uses [ccstatusline](https://www.npmjs.com/package/ccstatusline),
an npm package that renders a pre-built status bar in the terminal. The
wrapper script at `claude-statusline/statusline.sh` pipes session JSON
through it:

```bash
#!/usr/bin/env bash
input=$(cat)
export CCSTATUSLINE_CLAUDE_SESSION_ID=$(jq -r '.session_id' <<< "$input")
echo "$input" | bunx -y ccstatusline@latest
```

### Configuration

The status line is configured in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.agents/claude-statusline/statusline.sh",
    "padding": 0
  }
}
```

### Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `bun` | Runs `bunx ccstatusline` | `brew install bun` |
| `jq` | Extracts `session_id` from JSON | `brew install jq` |
| `ccstatusline` | Renders the status bar | auto-fetched by `bunx` |

See [dependency.md](../dependency.md) for the full setup guide.

---

## Status line overview

The status line is a customizable bar at the bottom of Claude Code. It runs
a shell script you configure, receives JSON session data on stdin, and
displays whatever your script prints to stdout.

### When it updates

The script runs after each new assistant message, when the permission mode
changes, or when vim mode toggles. Updates are debounced at 300ms. If a new
update triggers while the script is still running, the in-flight execution
is cancelled.

### What your script can output

- **Multiple lines:** each `echo` or `print` statement displays as a
  separate row.
- **Colors:** use ANSI escape codes (for example, `\033[32m` for green).
- **Links:** use OSC 8 escape sequences to make text clickable
  (Cmd+click on macOS). Requires a supporting terminal like iTerm2,
  Kitty, or WezTerm.

The status line runs locally and does not consume API tokens.

---

## Available data

Claude Code sends the following JSON fields to your script via stdin.

| Field | Description |
|-------|-------------|
| `model.id`, `model.display_name` | Current model identifier and display name |
| `cwd`, `workspace.current_dir` | Current working directory (prefer `workspace.current_dir`) |
| `workspace.project_dir` | Directory where Claude Code was launched |
| `cost.total_cost_usd` | Total session cost in USD |
| `cost.total_duration_ms` | Wall-clock time since session start (ms) |
| `cost.total_api_duration_ms` | Time waiting for API responses (ms) |
| `cost.total_lines_added` | Lines of code added |
| `cost.total_lines_removed` | Lines of code removed |
| `context_window.total_input_tokens` | Cumulative input tokens across session |
| `context_window.total_output_tokens` | Cumulative output tokens across session |
| `context_window.context_window_size` | Max context window size (200000 or 1000000) |
| `context_window.used_percentage` | Pre-calculated percentage of context used |
| `context_window.remaining_percentage` | Pre-calculated percentage remaining |
| `context_window.current_usage` | Token counts from the last API call |
| `exceeds_200k_tokens` | Whether the last response exceeded 200k tokens |
| `session_id` | Unique session identifier |
| `transcript_path` | Path to conversation transcript file |
| `version` | Claude Code version |
| `output_style.name` | Name of the current output style |
| `vim.mode` | Current vim mode (`NORMAL` or `INSERT`), if enabled |
| `agent.name` | Agent name, if running with `--agent` flag |

### Full JSON schema

```json
{
  "cwd": "/current/working/directory",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.jsonl",
  "model": {
    "id": "claude-opus-4-6",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory"
  },
  "version": "1.0.80",
  "output_style": {
    "name": "default"
  },
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 8,
    "remaining_percentage": 92,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "exceeds_200k_tokens": false,
  "vim": {
    "mode": "NORMAL"
  },
  "agent": {
    "name": "security-reviewer"
  }
}
```

**Fields that may be absent:**

- `vim` — only present when vim mode is enabled
- `agent` — only present when running with `--agent` or agent settings

**Fields that may be null:**

- `context_window.current_usage` — null before the first API call
- `context_window.used_percentage`,
  `context_window.remaining_percentage` — may be null early in the
  session

### Context window fields

The `context_window` object provides two ways to track usage:

- **Cumulative totals** (`total_input_tokens`, `total_output_tokens`):
  sum of all tokens across the session. Useful for tracking total
  consumption.
- **Current usage** (`current_usage`): token counts from the most recent
  API call. Use this for accurate context percentage.

The `used_percentage` field is calculated from input tokens only:
`input_tokens + cache_creation_input_tokens + cache_read_input_tokens`.
It does not include `output_tokens`.

---

## Writing a custom script

If you want to replace `ccstatusline` with your own script, create a
file (for example, `~/.claude/statusline.sh`), make it executable, and
point `settings.json` at it.

### Minimal example

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' \
  | cut -d. -f1)

echo "[$MODEL] ${PCT}% context"
```

### Test with mock input

```bash
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":25}}' \
  | ./statusline.sh
```

### Tips

- Keep output short — the status bar has limited width.
- Cache slow operations (for example, `git status`) to a temp file and
  refresh every few seconds. Each invocation runs as a new process, so
  use a fixed filename like `/tmp/statusline-git-cache`.
- Handle null values with fallbacks (for example, `// 0` in jq).

---

## Disabling the status line

Run `/statusline clear` inside Claude Code, or remove the `statusLine`
field from `settings.json`.

## Troubleshooting

**Status line not appearing:**

- Verify the script is executable: `chmod +x statusline.sh`
- Check that `disableAllHooks` is not set to `true` in settings
- Run the script manually to verify it produces output

**Shows `--` or empty values:**

- Fields may be null before the first API response completes
- Handle null values with fallback defaults in your script

**Context percentage shows unexpected values:**

- Use `used_percentage` rather than cumulative totals for accuracy
- Cumulative `total_input_tokens` may exceed the context window size

## Further reading

- [ccstatusline on npm](https://www.npmjs.com/package/ccstatusline)
- [starship-claude](https://github.com/martinemde/starship-claude) —
  alternative status line using Starship prompt
- [Official Claude Code status line docs](https://docs.anthropic.com/en/docs/claude-code/statusline)
