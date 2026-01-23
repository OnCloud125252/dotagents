---
name: Create or update AGENTS.md
description: Create or update AGENTS.md from recent git commits
---

Create or update the AGENTS.md file based on the pull request changes.

Instructions:
- First, check if AGENTS.md already exists in the repository root
- If AGENTS.md exists:
  - Review the pull request changes to understand what code was modified
  - Determine if the AGENTS.md needs updates based on the PR changes
  - If updates are needed, leave a commit suggestion comment on the PR with the proposed AGENTS.md changes
  - If no updates are needed, leave a comment explaining why
- If AGENTS.md does NOT exist:
  - Quickly scan key files (package.json, README.md, directory structure) to understand the project - be efficient, don't read everything
  - Create an initial AGENTS.md file with essential information for AI agents (build commands, testing instructions, code style, key architectural decisions)
  - Open a new pull request to the base branch with the new AGENTS.md file
  - Link the new PR to the original PR that triggered this workflow

Focus on information that helps AI coding agents work effectively with this codebase.
