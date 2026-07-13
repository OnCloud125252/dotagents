# .claude Template

**A batteries-included starter kit for extending Claude Code with custom commands, skills, hooks, and status line integrations.**

## What's Inside

- **26 slash commands** — git workflows, PR automation, worktree management, Linear integration, docs, and more
- **20 skills** — contextual agents that activate automatically (React best practices, Next.js, commit conventions, humanizer, i18n, etc.)
- **5 hooks** — native macOS notifications, session persistence, and worktree suggestions
- **Custom status line** — git state, working directory, and last prompt at a glance

<details>
<summary>Project structure (Click to expand)</summary>

```
.
├── commands/           # Slash commands (/git:commit, /pr:create, etc.)
├── skills/             # Contextual agent skills
├── hooks/              # Event-driven shell scripts
├── claude-statusline/  # Terminal status line scripts
├── store/              # Machine-readable catalog for selective install
├── agentsmd-templates/ # Reusable AGENTS.md snippets
├── gemini-commands/    # Auto-converted Gemini CLI equivalents
├── helpers/            # Shared utility scripts
├── templates/          # Reusable file templates
└── dependency.md       # External tool requirements
```

</details>

## Install

Copy the contents of [`store-prompt.md`](./store-prompt.md) into a Claude Code conversation. It will:

1. Fetch the catalog from this repo
2. Show you what's available and what you already have installed
3. Let you pick individual items or bundles
4. Install only what you chose into `~/.claude/`
5. Check and resolve dependencies

### Alternative: full clone

```bash
git clone https://github.com/OnCloud125252/dotagents.git ~/.agents
brew install jq trash ripgrep bun
ln -s ~/.agents/commands ~/.claude/commands
ln -s ~/.agents/skills ~/.claude/skills
```

## Optional Features

| Feature | Setup |
|---------|-------|
| **Status line** | `bunx -y ccstatusline@latest` |
| **Full dependency list** | See [`dependency.md`](./dependency.md) |
