# Development Workflow

## Task Execution
- **Testing**: Always run tests after changes (if scripts exist) and run linting/typechecking before completion.
- **Background Tasks**: Avoid `bun run dev` or background processes; use foreground execution for visibility.
- **Tools**:
  - Use `ripgrep` (`rg`) or the `Grep` tool instead of standard `grep`.
  - Always use **absolute paths**.

## File Safety
- **Deletion**: **ALWAYS** use `trash` instead of `rm`.
  - `trash file.txt` (recoverable) vs `rm` (permanent).
  - Use `trash -r dir/` for directories.
