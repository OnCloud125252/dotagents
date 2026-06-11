# SSH Inline Python

- Running a Python f-string with escaped quotes inside an SSH heredoc (`f"{b[\"Name\"]}"`) causes a SyntaxError — use an inline temporary variable, or switch to `python3 -c '...'` wrapping the whole thing in single quotes
