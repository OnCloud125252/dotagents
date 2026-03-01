# Skills

> Installed agent skills that extend AI assistant capabilities.

## Overview

Skills live in the `skills/` directory. Each skill has a `SKILL.md` that
defines its behavior, scope, and trigger conditions. Skills are invoked
automatically when the assistant detects a matching context, or manually
via slash commands.

## Quick reference

| Skill | Purpose | Trigger |
|---|---|---|
| `code-simplifier` | Refine recently modified code for clarity | Automatic after code changes |
| `docs-writer` | Write and edit Gemini CLI documentation | User requests doc work |
| `find-skills` | Discover and install skills from [skills.sh](https://skills.sh/) | "find a skill for…", "is there a skill…" |
| `frontend-design` | Build distinctive, production-grade UI | "build a page", "create a component" |
| `humanizer` | Remove AI writing patterns from text | "humanize this", editing/review tasks |
| `react-doctor` | Scan React code for issues (0–100 score) | After making React changes |
| `readme` | Write Plain package READMEs | README creation or editing |
| `update-docs` | Update Next.js docs based on code changes | "update docs for this PR" |
| `using-git-worktrees` | Create isolated git worktrees safely | "start a worktree", feature isolation |

## Skill details

### code-simplifier

Autonomous code refinement specialist. Operates on recently modified code
unless given a specific target. Preserves all functionality — only changes
*how* code is written, not *what* it does.

Key rules:
- Reduces nesting and eliminates redundancy
- Avoids nested ternaries — prefers `switch` or `if/else`
- Applies project standards from CLAUDE.md
- Will not over-simplify at the expense of readability

### docs-writer

Technical writing skill for Gemini CLI documentation. Follows a 4-step
workflow: clarify the request, read relevant source code, write or edit
following the project style guide (`references/style-guide.md`), then
verify links and formatting.

### find-skills

Helps discover and install agent skills from the open ecosystem. Uses the
`npx skills` CLI:

```bash
npx skills find [query]          # Search for skills
npx skills add <owner/repo@skill> # Install a skill
npx skills check                 # Check for updates
npx skills update                # Update installed skills
```

### frontend-design

Creates distinctive frontend interfaces with high aesthetic intentionality.
Commits to a bold design direction (brutalist, maximalist, retro-futuristic,
etc.) before writing code. Explicitly avoids generic fonts (Inter, Roboto)
and cliche AI aesthetics (purple gradients on white).

### humanizer

Removes AI writing patterns from text based on Wikipedia's "Signs of AI
writing" guide. Detects and fixes 24 patterns, including:

- Significance inflation ("pivotal moment", "testament to")
- AI vocabulary ("delve", "showcase", "underscore", "tapestry")
- Em dash and boldface overuse
- Sycophantic openers ("Great question!")
- Vague attributions ("experts say")

Goes beyond pattern removal — injects personality, opinions, and rhythm
variation.

### react-doctor

Scans a React codebase for security, performance, correctness, and
architecture issues. Outputs a 0–100 score with actionable diagnostics.

```bash
npx -y react-doctor@latest . --verbose --diff
```

Run after making React changes, fix reported errors, then re-run to verify
score improvement.

### readme

Guidelines for writing READMEs for Plain package repositories. Enforces a
strict 7-section structure:

1. H1 with package name
2. Bold one-liner description
3. Table of contents
4. Overview with working examples
5. Feature sections
6. FAQs (second to last)
7. Installation (always last)

Uses a conversational tone: "You can…" not "The module provides…".

### update-docs

Guided workflow for updating Next.js documentation based on code changes on
the active branch. Maps source file paths to doc file paths using
`references/CODE-TO-DOCS-MAPPING.md`, identifies gaps, and applies changes
with user confirmation at each step.

### using-git-worktrees

Creates isolated git worktrees with systematic directory selection and
safety verification. Checks `.gitignore` before creating project-local
worktree directories. Auto-detects the project type (Node, Rust, Python,
Go) and runs the appropriate install and test commands.

Directory priority:
1. `.worktrees/` (hidden, preferred)
2. `worktrees/` (alternative)
3. CLAUDE.md preference (if specified)
4. Ask the user

## Managing skills

```bash
npx skills find [query]    # Discover new skills
npx skills add <skill>     # Install a skill
npx skills check           # Check for updates
npx skills update          # Update all skills
npx skills init            # Create a custom skill
```

See the [find-skills](#find-skills) skill for more details.
