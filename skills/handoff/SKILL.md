---
name: handoff
description: >-
  Generates a durable, standalone session handoff document and outputs a resumption prompt for the next agent session.
argument-hint: [instruction]
disable-model-invocation: true
---

1. **Determine Topic & Directory:**
   - Parse the `<instruction>` to create a clean, kebab-case directory name: `<topic-name>`.
   - The file target **must** be: `~/.agents/handoffs/<topic-name>/YYYY-MM-DD-handoff.md`.
   - *Never* save handoffs in a session scratchpad, `/tmp`, or inside the project repository working tree.

2. **Gather & Structure Handoff Content:**
   Construct a standalone Markdown document adhering to the following structure:

   - **Authority & Scope:** Explicitly state that session-bound grants do not transfer and must be re-requested by the successor.
   - **Verified Baseline:**
     - Current git branch and commit hash (if applicable).
     - Environment state and working directory.
   - **Context & Goal:** High-level summary of the effort and why a handoff is taking place.
   - **Open Items & Action Plan:** Categorized task list with assigned owners/status.
   - **Canonical Pointers:** Links or references to tracker issues, PRs, or design docs (avoid duplicating full specs).
   - **Unverified Claims & Risks:** Flag any facts, assumption checks, or system behavior that have *not* been hard-verified so the successor knows to re-test them.

3. **Execute File Creation:**
   - Write the generated document to `~/.agents/handoffs/<topic-name>/YYYY-MM-DD-handoff.md`. Create parent directories as needed.

4. **Output the Resumption Prompt:**
   - After saving the file, present a clear **Handoff Prompt** to the user so they can copy-paste it into the next agent session.
