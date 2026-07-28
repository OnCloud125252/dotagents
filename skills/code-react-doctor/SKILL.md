---
name: code-react-doctor
description: Scan React codebase for security, performance, correctness, and architecture issues. Outputs a 0-100 score with actionable diagnostics.
allowed-tools: Bash(npx *), Read
disable-model-invocation: true
---

# React Doctor

Scans your React codebase for security, performance, correctness, and architecture issues. Outputs a 0-100 score with actionable diagnostics.

## Usage

```bash
npx -y react-doctor@latest . --verbose --diff
```

## Workflow

Run after making changes to catch issues early. Fix errors first, then re-run to verify the score improved.
