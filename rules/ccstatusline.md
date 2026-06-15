---
paths:
  - "**/claude-statusline/*.sh"
  - "**/ccstatusline/settings.json"
---

# ccstatusline custom commands

Scripts under `claude-statusline/` are wired into ccstatusline as `custom-command`
widgets (`commandPath` in `~/.config/ccstatusline/settings.json`) and run once per
render in **every** Claude session sharing the global config.

- **Always `exit 0`** — a non-zero exit renders as `[Exit: N]` in the widget, even
  with empty stdout. Watch the `[ -n "$x" ] && echo "$x"` footgun: as the last line
  it returns 1 when `$x` is empty.
- **No controlling terminal** — custom commands are spawned detached, so `tty`
  resolves to `??`. Do not identify the session by tty.
- **Process ancestry is intact** — walk `ps -o ppid=,comm=` from `$$` up to the
  `claude` process to identify the current session when tty/cwd are insufficient.
- **Cheap and non-blocking** — runs on every render; cap network calls
  (`curl --max-time 1`) and print blank rather than error when data is unavailable.
