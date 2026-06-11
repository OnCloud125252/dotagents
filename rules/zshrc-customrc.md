---
paths:
  - "**/.zshrc"
  - "**/.bashrc"
  - "**/.zprofile"
  - "**/.bash_profile"
  - "**/.zshenv"
---

# Shell RC + CustomRC

`~/.zshrc` is a thin loader for **CustomRC** at `~/.customrc/`. Do NOT add new config directly to `~/.zshrc` — add a module instead.

- **Modules**: `~/.customrc/rc-modules/{Global,Darwin,Linux}/<tool>.sh` — one file per tool/topic. `Global/` is cross-platform; `Darwin/` macOS-only; `Linux/` Linux-only.
- **Find existing first**: search `~/.customrc/rc-modules/` for the tool before creating a new file. Many tools (fzf, fzf-tab, bat, eza, zoxide, atuin, etc.) already have dedicated modules.
- **Style**: 2-space indent. Match the surrounding module's pattern (env vars, `zstyle`, `cache_init` for slow init, `add-zsh-hook precmd` for lazy load).
- **Apply changes**: `customrc cache rebuild && exec zsh` to pick up edits now. Otherwise auto-rebuilds on next shell start (mtime invalidation in `customrc.sh:157`).
- **Never edit** `~/.customrc/customrc.sh` or `~/.customrc/helpers/*` — repo-managed. Only `rc-modules/` is user config.
