---
name: Convert Commands to Gemini
description: Convert Claude Code commands (.md) into Gemini CLI commands (.toml)
argument-hint: [--dry] [--only name1,name2]
allowed-tools: Read, Write, Glob, Bash(ls:*), Bash(mkdir:*)
model: claude-sonnet-4-6
---

Convert all Claude Code commands from `commands/` into Gemini CLI TOML commands in `gemini-commands/`.

### Arguments

Parse `$ARGUMENTS` to extract:

- **--dry**: Optional. Preview the conversion without writing files
- **--only**: Optional. Comma-separated list of command names to convert (e.g., `git:commit,pr:create`). If omitted, convert all commands.

### Naming Convention

Commands in subdirectories use `:` as a namespace separator in the output filename:

- `commands/git/commit.md` → `gemini-commands/git:commit.toml`
- `commands/pr/create.md` → `gemini-commands/pr:create.toml`
- `commands/search.md` → `gemini-commands/search.toml`

The relative path from `commands/` is converted by replacing `/` with `:` and `.md` with `.toml`.

### Conversion Rules

For each `.md` file in `commands/` (recursively, excluding this command itself):

1. **Parse YAML front matter** to extract metadata fields
2. **Map fields to TOML**:
   - `description` -> top-level `description = "..."` in TOML
   - `name` and `argument-hint` -> keep as YAML front matter block inside the `prompt` string
   - `model` -> **drop** (Claude-specific)
   - `allowed-tools` -> **drop** (Claude-specific)
3. **Transform the body**:
   - Replace all occurrences of `$ARGUMENTS` with `{{args}}`
   - Replace `$1`, `$2`, etc. with `{{args}}` (Gemini does not support positional args)
   - Remove any references to Claude-specific tools (e.g., "Invoke the /commit skill using the Skill tool") and replace with equivalent Gemini-native instructions
   - Keep all other Markdown content intact
4. **Write the TOML file** to `gemini-commands/<colon-separated-name>.toml`

### TOML Output Format

```toml
description = "<description from front matter>"

prompt = """
---
name: <name from front matter>
argument-hint: <argument-hint if present>
---

<converted body content>
"""
```

- Use triple-quoted strings (`"""`) for the `prompt` field
- Escape any literal `"""` sequences inside the prompt body (replace with `\"\"\"`)
- Ensure the TOML is valid — no unbalanced quotes or special characters breaking syntax
- The YAML front matter inside `prompt` should only contain `name` and `argument-hint` (if present)

### Process

1. **Discover**: Use Glob to find all `commands/**/*.md` files (recursive)
2. **Filter**: Skip this command itself. If `--only` is set, filter to only those names (using `:` notation, e.g., `git:commit`).
3. **Ensure target directory**: Create `gemini-commands/` if it does not exist
4. **Convert each file**:
   a. Read the `.md` file
   b. Compute the output name: take the path relative to `commands/`, replace `/` with `:`, replace `.md` with `.toml`
   c. Parse front matter and body
   d. Apply conversion rules above
   e. If `--dry`, display the TOML output without writing
   f. Otherwise, write to `gemini-commands/<colon-separated-name>.toml`
5. **Report**: After all conversions, display a summary table:

```
Command              Status
─────────────────────────────
git:commit           converted
pr:create            converted
search               converted
...
```

### Important

- Preserve the original `.md` files — do not modify or delete them
- If a `.toml` file already exists, overwrite it (this is a sync operation)
- The TOML file name is derived from the relative path (e.g., `commands/git/commit.md` → `git:commit.toml`, `commands/search.md` → `search.toml`)
