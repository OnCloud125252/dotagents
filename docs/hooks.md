# Hooks

> macOS notifications triggered by Claude Code lifecycle events.

## How it works

`hooks/notify.sh` listens for Claude Code hook events via stdin JSON. It
extracts the event type and builds a dynamic notification using
[growlrrr](https://github.com/moltenbits/growlrrr) (`grrr`).

Clicking any notification opens WezTerm (`com.github.wez.wezterm`).

## Events

| Event | Subtitle | Sound | Message content |
|---|---|---|---|
| **Stop** | Operation Finished | Hero | Last assistant message (truncated to 200 chars) |
| **Notification** | Input Needed | Glass | The notification message from Claude Code |

### Stop event

Fires when Claude Code finishes an operation. The script:

1. Checks `stop_hook_active` — exits early if `true` to prevent infinite loops
2. Extracts `last_assistant_message` — exits if empty
3. Truncates the message to 200 characters, appending `......` and
   `[See terminal for full message]` if needed
4. Sends the notification grouped by `session_id`

### Notification event

Fires when Claude Code needs user input (e.g., permission prompts). The script
sends the raw `.message` field as the notification body.

## Configuration

Register the hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "~/.agents/hooks/notify.sh"
      }
    ],
    "Notification": [
      {
        "type": "command",
        "command": "~/.agents/hooks/notify.sh"
      }
    ]
  }
}
```

## JSON input fields

The script reads these fields from the stdin JSON:

| Field | Used in | Description |
|---|---|---|
| `hook_event_name` | Both | Event type (`Stop` or `Notification`) |
| `cwd` | Both | Working directory — basename used as project name in title |
| `stop_hook_active` | Stop | Guard flag to prevent recursive hook calls |
| `last_assistant_message` | Stop | Final assistant message text |
| `session_id` | Both | Groups notifications by session via `--threadId` |
| `message` | Notification | The notification message content |

## Dependencies

| Tool | Purpose | Install |
|---|---|---|
| `jq` | Parses JSON from stdin | `brew install jq` |
| `grrr` | Sends macOS notifications | See [dependency.md](../dependency.md#growlrrr-grrr-v120) |

## Files

| File | Purpose |
|---|---|
| `hooks/notify.sh` | Main notification hook script |
| `hooks/claude-icon.png` | Claude icon displayed in notifications |

## Troubleshooting

**No notifications after Stop:**

- Verify `stop_hook_active` is not stuck at `true` in the event JSON
- Ensure `last_assistant_message` is not empty — the script silently exits
  on empty messages

**Notifications not appearing at all:**

- Check macOS notification permissions for growlrrr / claude-code app
- See the [growlrrr troubleshooting section](../dependency.md#troubleshooting) in dependency.md

**Wrong terminal opens on click:**

- The script hardcodes `open -b com.github.wez.wezterm`. Edit the
  `--execute` flag in `notify.sh` to use a different terminal's bundle ID.
