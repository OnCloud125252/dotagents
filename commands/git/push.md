---
name: Push
allowed-tools: Bash(git:*), Bash(pwd), AskUserQuestion, Read
description: Run `git push` and resolve issues if there's any output from git hook, and ask user how to resolve conflicts
model: claude-haiku-4-5
---

Push the current branch to the remote repository and handle any issues that arise.

### Process

1. **Verify Environment**: Run `pwd` and confirm you're in a git repository. Check the current branch with `git branch --show-current`.

2. **Pre-push Check**: Run `git status` to confirm there are commits to push. Run `git log @{u}..HEAD --oneline 2>/dev/null` to show what will be pushed.

3. **Push Changes**: Run `git push` (with `-u origin <branch>` if no upstream is set) and capture the output.

4. **Handle Results**:

   - **Clean push**: Report success with a summary of what was pushed.

   - **Rejected (non-fast-forward)**: The remote has changes you don't have locally.
     1. Inform the user their push was rejected
     2. Ask the user how to proceed:
        - **Pull and retry** (`git pull` then `git push`)
        - **Pull with rebase** (`git pull --rebase` then `git push`)
        - **Abort** — do nothing
     3. NEVER suggest or use `--force` unless the user explicitly requests it

   - **Hook output**: If pre-push hooks produce output or errors, display the output and diagnose the issue. Attempt to fix automatically if possible (e.g., linting errors), then retry the push.

   - **Authentication errors**: Display the error and suggest the user check their credentials or SSH keys.

   - **Other errors** (network, permission, etc.): Display the error and suggest next steps.

### Important

- NEVER use `--force` or `--force-with-lease` unless the user explicitly asks
- NEVER use `--no-verify` to skip hooks — fix the underlying issue instead
- Always show the user what will be pushed before pushing
- When in doubt, ask the user before proceeding
