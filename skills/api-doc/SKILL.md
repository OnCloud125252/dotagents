---
name: api-doc
description: >
  Generate a frontend-oriented API guide document for a given issue or task.
  Analyzes git diff and source code to identify API changes (GraphQL, REST,
  gRPC, tRPC, etc.), then creates a comprehensive document with types, endpoints,
  examples, validation rules, and error handling. Publishes to the project's
  issue tracker (Linear, GitHub, Notion, etc.) if available. Use when the user
  asks to "create an API doc", "write frontend API guide", "document the API
  changes", or after completing backend API work that frontend needs to consume.
  Also use when the user says "寫 API 文件", "產生前端文件", or "建立文件".
user-invocable: true
disable-model-invocation: false
---

Generate a frontend-oriented API guide document and publish it to the project's issue tracker.

## Arguments

An issue ID, URL, or description of what to document (e.g., `<ISSUE-ID>`, a Linear/GitHub URL, or a short description like "sponsor CRUD API").
If not provided, ask the user for it.

## Workflow

### 1. Parse Input & Fetch Context

`$ARGUMENTS` may be:

| Input | Example | Action |
|---|---|---|
| Issue identifier | `<ISSUE-ID>`, `#<N>` | Fetch from issue tracker |
| Full URL | `https://linear.app/.../<ISSUE-ID>/...` | Extract identifier, fetch |
| Free-form description | `sponsor CRUD API` | Use as context for what to document |
| Empty | | Ask the user |

If an issue tracker MCP is available (Linear, GitHub, etc.), fetch the issue to get title, project, team, and branch name. If multiple MCP servers exist, pick the one matching the issue's prefix.

### 2. Detect API Technology

Scan the project for the API surface:

| File Pattern | API Type |
|---|---|
| `**/*.graphqls`, `**/*.graphql` | GraphQL |
| `**/*.proto` | gRPC / Protocol Buffers |
| `**/openapi.yaml`, `**/swagger.json` | REST / OpenAPI |
| `**/routes/**`, `**/controllers/**` | REST (framework) |
| tRPC imports in `**/*.ts` | tRPC |

### 3. Analyze Changes

Run `git diff main...HEAD` filtered to API-relevant files.

If the diff is empty, fall back to reading source files directly — use the issue title, branch name, and recent commits as hints.

Read **complete** type/schema definitions from the source files. The document shows full types, not partial diffs.

Also check the implementation layer (resolvers, controllers, handlers, service methods) to understand:
- Permission / authentication requirements
- Validation rules and error conditions
- Special behavior (graceful degradation, ownership checks, pagination, rate limits)

### 4. Determine Language

- If the project has Chinese documentation or the user communicates in Chinese → **Traditional Chinese (zh-TW)**
- Otherwise → **English**

### 5. Compose the Document

Adapt this structure based on the API type — skip sections that don't apply, add sections for project-specific concerns (webhooks, file uploads, pagination cursors, subscriptions).

```markdown
# [Feature Name] — Frontend API Guide

## Overview
One-paragraph summary of what's available.

## Types / Models
Full type definitions in code blocks (GraphQL, TypeScript, Proto, JSON Schema, etc.)

## Queries / GET Endpoints
For each read operation:
- What it does
- Full example with realistic field selections / parameters
- Notes on nullable fields, pagination, filtering

## Mutations / Write Endpoints
For each write operation:
- What it does
- Full example with realistic input values
- Input type / request body definition
- Notes (immutable fields, partial update, idempotency)

## Validation Rules
Bullet list of constraints.

## Error Handling
| Scenario | Error Code / Status |
Table covering auth, validation, not-found, conflict, rate-limit scenarios.

## Authentication & Permissions
What auth is required, what scopes or roles.
```

### 6. Publish the Document

Publish to the issue tracker that's available via MCP:

| Tracker | Action |
|---|---|
| **Linear** | `save_document` attached to the issue, then `save_comment` with link |
| **GitHub** | Create as a PR comment, wiki page, or issue comment |
| **Notion** | Create a page in the relevant database/workspace |
| **None available** | Output the document as markdown in the conversation |

After publishing, post a comment on the issue linking to the document with a 2-3 line summary.

### 7. Report

Tell the user the document URL (if published) and offer to adjust scope, add examples, or change language.

## Style Guidelines

- Use realistic example values, not placeholders
- Explicitly call out immutable fields, nullable returns, partial update support, breaking changes
- If the API uses pagination, show a complete pagination example
- For mutations with side effects (emails, webhooks), document them
- Keep it practical — copy-paste ready for frontend consumption
