# Linear MCP Gotchas

- `save_document` with `id` is a **full replacement**, not a patch — you must repaste the complete content
- The `icon` field rejects arbitrary emoji (returns InputValidationError); recommend omitting it
- Use real newlines in content; `\n` literal strings will be treated as literal characters
- `list_issues` filtered by project **slug** silently returns `[]` — pass the project **UUID** (or exact name) instead
- `save_issue` can set but not clear `dueDate` — the field has no null option (unlike `cycle`/`assignee`/`parentId`); `null` and `""` both 400. Clear via GraphQL `issueUpdate(input:{dueDate:null})` or the UI
- Read issue `assignee`/`status` before bulk-updating — some fields (e.g. `dueDate`) can't be reverted via the tool, so a wrong write is costly to undo
