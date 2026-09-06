---
name: update-dependencies
description: Scan the repo for external tool dependencies and rewrite dependency.md. Invoke /update-dependencies after you add a skill or script that needs a new CLI, package, API, or env var.
disable-model-invocation: true
user-invocable: true
---

Scan all project source directories for external dependencies and update `dependency.md` to reflect the current state.

### Directories to Scan

Read **every** file in these directories (recursively):

1. `skills/` — skill definitions (`SKILL.md`, `skill.md`, and any scripts)
2. `hooks/` — hook scripts (`.sh` files)
3. `helpers/` — helper scripts
4. `claude-statusline/` — statusline scripts

### What Counts as a Dependency

Identify anything the project **cannot function without** that isn't a shell builtin (`echo`, `cd`, `[`, `test`, `read`, `export`, etc.) or a POSIX coreutil (`cat`, `head`, `tail`, `mkdir`, `mv`, `cp`, `rm`, `wc`, `date`, `stat`, `tr`, `sed`, `awk`, `find`, `sort`, `uniq`, `cut`, `basename`, `dirname`, `tee`, `xargs`).

Categories to detect:

| Category | Examples |
|---|---|
| **Homebrew packages** | `jq`, `ripgrep`, `trash`, `bun` |
| **Homebrew taps** | `moltenbits/tap` (growlrrr) |
| **npm / bunx packages** | `ccstatusline`, `react-doctor`, `skills` |
| **CLI tools** | `gh` (GitHub CLI), `git`, `grrr`/`growlrrr`, `npm`, `npx`, `pnpm`, `uv`, `tput` |
| **macOS utilities** | `pbcopy`, `open`, `osascript` |
| **APIs & services** | OpenAI API, external URLs called via `curl`/`fetch` |
| **MCP servers** | Any `mcp__*` tool references |
| **Python packages** | `openai`, `pillow`, etc. |
| **Environment variables** | API keys or config vars required at runtime |
| **Applications** | WezTerm, etc. |

### Detection Heuristics

For each file, look for:

- Direct command invocations: `jq`, `gh`, `grrr`, `bunx`, `npx`, etc.
- `which <tool>` or `command -v <tool>` checks
- `brew install` / `brew tap` references
- `bunx -y <package>` / `npx <package>` patterns
- `curl` / `fetch` calls to external APIs
- `mcp__` prefixed tool names in prompt text
- `pip install` / `uv pip install` patterns
- Environment variable reads (`$VAR_NAME`, `${VAR_NAME}`) that are API keys or config
- `open -b <bundle-id>` or `open -a <app>` patterns

### Output Format

Rewrite `dependency.md` preserving the existing structure and style. Use the current file as a template for tone and formatting.

The file must contain:

1. **Title**: `# Project Dependencies`
2. **Intro line**: one sentence overview
3. **Quick Setup** section: a single copy-paste block that installs everything (group by install method: brew, brew tap, bunx, etc.)
4. **One section per dependency** (separated by `---`), each with:
   - **H2 heading**: dependency name
   - Brief description of what it does (one sentence)
   - **Install:** installation command
   - **Used by:** list of files that depend on it (paths relative to project root)
   - Any additional subsections only if the dependency has non-obvious setup (e.g., growlrrr's `authorize` + `apps add` steps, or API key configuration)

### Rules

- **Preserve existing detail** for dependencies that are already documented (e.g., growlrrr's troubleshooting section, trash's subcommands table). Only update the "Used by" list and add/remove dependencies.
- **Remove** dependencies that are no longer referenced anywhere.
- **Add** newly discovered dependencies with the same formatting style.
- **Sort** dependency sections alphabetically by name.
- Keep the Quick Setup block in sync — it must install every dependency listed below it.
- Do NOT list shell builtins or POSIX coreutilities as dependencies.
- Do NOT list the agent's built-in tools (read, write, edit, grep, find, bash, web search, etc.) as dependencies.

### Process

1. Discover all files in the scan directories
2. Read each file and extract dependencies
3. Read the current `dependency.md`
4. Diff what's documented vs. what's detected
5. Write the updated `dependency.md`
6. Report a summary of changes (added, removed, updated)
