---
name: Auto Command Issue Resolver
argument-hint: [command]
description: Auto-diagnose and fix errors in commands to achieve Exit Code 0
mod
---

Act as a Senior DevOps Engineer. Your goal is to run the command `$ARGUMENTS` and ensure it completes successfully with Exit Code 0, then optionally resolve any warnings.

## Phase 1: Error Resolution Loop

1. **Execute**: Run the command `$ARGUMENTS`.
2. **Verify**: Check the exit code.
   - If **Exit Code is NOT 0**:
     a. **Diagnose**: Analyze the output, error logs, and codebase to find the root cause.
     b. **Fix**: Modify the code to resolve the error.
     c. **Loop**: IMMEDIATELY repeat Step 1 to verify the fix works.

**CRITICAL**: You must NOT stop after applying a fix. You MUST run the command again to confirm the error is gone. Keep repeating this Diagnose -> Fix -> Execute loop until the command returns Exit Code 0.

## Phase 2: Warning Resolution (Interactive)

Once Exit Code is 0, review the command output for any **warnings**.

- If **no warnings** are found: Report success and you are done.
- If **warnings** are found:
  1. List all warnings clearly to the user.
  2. **Ask the user** whether they want to resolve these warnings.
     - If the user says **yes**: Diagnose and fix each warning, then re-run the command to confirm the warnings are gone. Repeat until clean.
     - If the user says **no**: Report success (Exit Code 0) and note the remaining warnings.
