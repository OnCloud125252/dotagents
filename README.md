# dotagents

**Skills, rules, and a global AGENTS.md for coding agents. Built for [pi](https://pi.dev/), also usable from Gemini CLI.**

## What's Inside

- **28 skills** — user-invoked workflows (git, PR, worktree, issue trackers, docs) plus contextual skills that activate automatically (React best practices, Next.js, writing style, and more)
- **Rules** — path-scoped instructions loaded by the [pi-rules](https://www.npmjs.com/package/@tigorhutasuhut/pi-rules) extension
- **Global AGENTS.md** — design principles and workflow rules shared by every project

<details>
<summary>Project structure (Click to expand)</summary>

```
.
├── GLOBAL_AGENTS.md    # Global instructions (symlinked to ~/AGENTS.md)
├── skills/             # Agent skills (auto-activating + user-invoked)
├── rules/              # Path-scoped rules
├── gemini-commands/    # Gemini CLI equivalents, generated from skills/
├── store/              # Machine-readable catalog
├── hooks/              # Legacy Claude Code hooks (not used by pi)
├── claude-statusline/  # Legacy ccstatusline scripts (not used by pi)
├── helpers/            # Shared utility scripts
└── dependency.md       # External tool requirements
```

</details>

## Install

```bash
git clone https://github.com/OnCloud125252/dotagents.git ~/.agents
brew install jq trash ripgrep bun
ln -s ~/.agents/GLOBAL_AGENTS.md ~/AGENTS.md
pi install npm:@tigorhutasuhut/pi-rules
```

pi discovers `~/.agents/skills/` on its own. pi-rules reads `~/.agents/rules/` on its own.

See [`dependency.md`](./dependency.md) for the full tool list.
