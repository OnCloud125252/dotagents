# Linear MCP Gotchas

- `save_document` with `id` is a **full replacement**, not a patch — you must repaste the complete content
- The `icon` field rejects arbitrary emoji (returns InputValidationError); recommend omitting it
- Use real newlines in content; `\n` literal strings will be treated as literal characters
