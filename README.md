# dotagents

**Skills, rules, and a global AGENTS.md for coding agents. Works with [pi](https://pi.dev/) and Claude Code.**

## What's Inside

- **28 skills** — user-invoked workflows (git, PR, worktree, issue trackers, docs) plus contextual skills that activate automatically (React best practices, Next.js, writing style, and more)
- **Prompt-native store** — paste one prompt into your agent to browse, install, and update only the skills you choose
- **Rules** — path-scoped instructions loaded by the [pi-rules](https://www.npmjs.com/package/@tigorhutasuhut/pi-rules) extension (pi only)
- **Global AGENTS.md** — design principles and workflow rules shared by every project

<details>
<summary>Project structure (Click to expand)</summary>

```
.
├── GLOBAL_AGENTS.md    # Global instructions (symlinked to ~/AGENTS.md)
├── skills/             # Agent skills (auto-activating + user-invoked)
├── rules/              # Path-scoped rules (pi only)
├── store/              # Machine-readable catalog for the prompt-native store
├── hooks/              # Claude Code hooks (not used by pi)
├── claude-statusline/  # ccstatusline scripts (not used by pi)
├── helpers/            # Shared utility scripts
└── dependency.md       # External tool requirements
```

</details>

## Install skills

**Skill installation is prompt-native: copy one prompt, then let your agent handle the rest.**

1. Open [`store-prompt.md`](./store-prompt.md) and copy its entire contents.
2. Paste it into a new agent session.
3. Choose the skills or bundles you want.

The store distributes the catalog's published top-level skills; rules and global instructions are not store packages. It detects skills in `~/.agents/skills/`, resolves dependencies, and installs only what you select.

Reload the session afterward, or start a new one. Contextual skills activate automatically. Explicit skills need a skill command: `/skill:<name>` in pi, `/<name>` in Claude Code.

Claude Code reads `~/.claude/skills`. Link it once so both agents share the same skills:

```bash
ln -s ~/.agents/skills ~/.claude/skills
```
