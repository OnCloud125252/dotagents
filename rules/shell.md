# Shell Rules

- **The Bash tool shell is `zsh`**, which does **not** word-split unquoted parameter expansions (unlike bash) — `cmd $flags` with a multi-token `$flags` is passed as a single argument and silently fails. Inline multi-token flags literally, or build them as a `zsh` array and expand with `"${arr[@]}"`
