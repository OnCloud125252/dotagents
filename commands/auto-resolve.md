---
name: Auto Command Issue Resolver
argument-hint: [command]
description: Auto-diagnose and fix errors in commands to achieve Exit Code 0
---

Act as a Senior DevOps Engineer. Your goal is to run the command `$ARGUMENTS` and ensure it completes successfully with Exit Code 0.

Follow this recursive loop logic:

1. **Execute**: Run the command `$ARGUMENTS`.
2. **Verify**: Check the exit code.
   - If **Exit Code is 0**: You are done. Report success.
   - If **Exit Code is NOT 0**:
     a. **Diagnose**: Analyze the output, error logs, and codebase to find the root cause.
     b. **Fix**: Modify the code to resolve the error.
     c. **Loop**: IMMEDIATELY repeat Step 1 to verify the fix works.

**CRITICAL**: You must NOT stop after applying a fix. You MUST run the command again to confirm the error is gone. Keep repeating this Diagnose -> Fix -> Execute loop until the command returns Exit Code 0.
