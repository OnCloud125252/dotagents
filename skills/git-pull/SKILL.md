---
name: git-pull
description: Run `git pull` and resolve issues if there's any output from git hook, and ask user how to resolve conflicts
disable-model-invocation: true
user-invocable: true
---

Pull the latest changes from the remote repository and handle any issues that arise.

### Process

1. **Verify Environment**: Run `pwd` and confirm you're in a git repository.

2. **Pull Changes**: Run `git pull` and capture the output.

3. **Handle Results**:

   - **Clean pull (fast-forward or already up to date)**: Report success with a brief summary of what changed (files updated, insertions, deletions).

   - **Merge conflicts**: If conflicts are detected:
     1. Run `git status` to identify conflicted files
     2. Show the list of conflicted files to the user
     3. Ask the user how they want to resolve each conflict:
        - **Keep ours** (`git checkout --ours <file>`)
        - **Keep theirs** (`git checkout --theirs <file>`)
        - **Manual merge** — open the file and let the user decide
        - **Abort the merge** (`git merge --abort`)
     4. After resolution, run `git add` on resolved files and complete the merge with `git commit`

   - **Hook output**: If pre-merge or post-merge hooks produce output or errors, display the full output to the user with suggested manual steps if needed. Post-merge hooks are designed for manual follow-up — do not attempt automatic fixes.

   - **Diverged branches**: If the local and remote have diverged, default to merge. Only rebase if the user explicitly requests it.

   - **Other errors** (authentication, network, etc.): Display the error and suggest next steps.

### Important

- NEVER use `--force` or destructive flags
- NEVER use interactive flags like `-i`
- Always show the user what happened before taking further action
- When in doubt, ask the user before proceeding
