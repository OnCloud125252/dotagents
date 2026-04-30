---
name: Linear API Doc
description: |
  Generate a frontend-oriented API guide document on Linear for a given issue.
  Analyzes git diff and source code to identify API changes, then creates a
  comprehensive document with types, endpoints, examples, validation rules,
  and error handling attached to the Linear issue.
argument-hint: <linear_issue_id | linear_issue_url>
---

Invoke the `api-doc` skill with `$ARGUMENTS` as the issue identifier.

The skill handles all steps: fetching issue context, detecting API technology, analyzing changes, generating the document, publishing it, and commenting on the issue.
