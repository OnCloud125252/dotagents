---
name: commit-message-style
description: Create a well-formatted git commit message based on the changes staged for commit. Follow best practices for commit message style and content.
user-invocable: false
disable-model-invocation: false
---

# Commit Best Practices Skill

When asked to create commits or work with git commits:
1. Run `git status` to see all untracked and modified files
2. Run `git diff` to review staged and unstaged changes
3. Run `git log` to see recent commit messages for style reference
4. Analyze changes and create a concise commit message (1-2 sentences, focus on "why")
5. Stage specific files by name rather than using `git add -A` or `git add .`
6. Create the commit with proper formatting
7. Verify the commit with `git status` after completion

## Commit Message Guidelines

**Type detection:**

- `feat`: New files, new functions/methods, new features
- `fix`: Changes to existing logic that resolve issues
- `docs`: Changes to .md, .txt, comments, or documentation files
- `style`: Formatting, whitespace, semicolons (no logic changes)
- `refactor`: Code restructuring without changing functionality
- `test`: Adding or modifying test files
- `chore`: Build scripts, configs, dependencies, tool changes
- `perf`: Performance improvements
- `ci`: CI/CD configuration changes

**Format rules:**

- Use imperative mood: "Add feature" not "Added feature"
- First line should be under 72 characters
- Reference issues/PRs when applicable

**Scope detection:**

- Derive from common directory or module name
- Use existing scopes from recent commits when applicable
- Omit if changes span multiple areas

**Description guidelines:**

- Start with lowercase verb (add, update, fix, remove, etc.)
- Keep under 50 characters
- Be specific but concise
- No period at the end

**Body guidelines (for complex changes):**

- Include if changes affect 3+ files or have breaking changes
- Explain the what and why, not the how
- Wrap at 72 characters
- Separate from subject with blank line

**Output format:**

- No markdown formatting in the commit message itself
- NEVER include "Generated with", "Co-authored-by", or any AI/tool attribution in the commit message
- No meta-information about how the message was created in the commit message


## Safety Rules
- Never run destructive commands like `git reset --hard`, `git push --force`, or `git clean -f`
- Never skip hooks (--no-verify) or bypass signing
- Always create new commits, never amend existing ones unless explicitly asked
