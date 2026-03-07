---
name: Create Commits
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*)
description: Create commits for recent changes. Multiple commits are allowed for logical grouping.
---

Create commits for all recent changes. You MUST split changes into multiple logical commits when appropriate — each commit should represent a single cohesive change. Invoke the /commit skill using the Skill tool to handle the commit creation

# Grouping Guidelines

- **DO split** when changes touch unrelated areas (e.g., a new feature + a docs update + a config change)
- **DO NOT split** tightly coupled changes that would break individually (e.g., a new function and its caller)
- Prefer 2-5 commits for a typical set of changes; use 1 if everything is truly cohesive
- If only one logical group exists, create a single commit — don't force artificial splits
