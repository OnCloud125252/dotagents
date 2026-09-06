---
name: convert-to-gemini-command
description: Convert every skills/*/SKILL.md into a Gemini CLI command (.toml) in gemini-commands/. Invoke /convert-to-gemini-command [--dry] [--only name1,name2].
disable-model-invocation: true
user-invocable: true
---

Convert all skills from `skills/` into Gemini CLI TOML commands in `gemini-commands/`.

### Arguments

Parse the arguments after the skill name to extract:

- **--dry**: Optional. Preview the conversion without writing files
- **--only**: Optional. Comma-separated list of skill names to convert (e.g., `git-commit,pr-create`). If omitted, convert all skills.

### Naming Convention

Skill directory names are flat kebab-case and map directly to the output filename:

- `skills/git-commit/SKILL.md` → `gemini-commands/git-commit.toml`
- `skills/pr-create/SKILL.md` → `gemini-commands/pr-create.toml`
- `skills/search/SKILL.md` → `gemini-commands/search.toml`

The skill directory name replaces `.md` with `.toml`. Legacy colon-named files (e.g. `git:commit.toml`) come from the removed `commands/` layout — report them as stale.

### Conversion Rules

For each `skills/*/SKILL.md` file (excluding `.system/` and nested subdirectories like `*/upstream/`):

1. **Parse YAML front matter** to extract metadata fields
2. **Map fields to TOML**:
   - `description` -> top-level `description = "..."` in TOML
   - `name` and `argument-hint` -> keep as YAML front matter block inside the `prompt` string
   - `disable-model-invocation` and `user-invocable` -> **drop** (meaningless in Gemini; every TOML command is user-invoked)
   - Any other harness-specific field (`model`, `allowed-tools`) -> **drop**
3. **Transform the body**:
   - Replace all occurrences of `$ARGUMENTS` with `{{args}}`
   - Replace `$1`, `$2`, etc. with `{{args}}` (Gemini does not support positional args)
   - Replace references to other skills (e.g., "Follow the `/git-commit` skill") with equivalent Gemini-native instructions
   - Keep all other Markdown content intact
4. **Write the TOML file** to `gemini-commands/<skill-name>.toml`

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

1. **Discover**: Find all `skills/*/SKILL.md` files (top level only)
2. **Filter**: If `--only` is set, filter to only those skill names
3. **Ensure target directory**: Create `gemini-commands/` if it does not exist
4. **Convert each file**:
   a. Read the `SKILL.md` file
   b. Compute the output name: skill directory name with `.toml` appended
   c. Parse front matter and body
   d. Apply conversion rules above
   e. If `--dry`, display the TOML output without writing
   f. Otherwise, write to `gemini-commands/<skill-name>.toml`
5. **Report stale files**: List any existing `.toml` files that no longer correspond to a skill (e.g. legacy colon-named files) and ask the user whether to delete them
6. **Report**: After all conversions, display a summary table:

```
Skill                Status
─────────────────────────────
git-commit           converted
pr-create            converted
search               converted
...
```

### Important

- Preserve the original `SKILL.md` files — do not modify or delete them
- If a `.toml` file already exists, overwrite it (this is a sync operation)
- The TOML file name is derived from the skill directory name (e.g., `skills/git-commit/SKILL.md` → `git-commit.toml`, `skills/search/SKILL.md` → `search.toml`)
