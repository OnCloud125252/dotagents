---
name: find-simplifications
description: 'Find non-obvious simplification candidates in any repository and turn them into evidence-backed proposals, inline TODO/FIXME/XXX markers, or a PR summary. Covers dead, duplicated, speculative, over-built, added-then-removed, and hand-rolled-where-a-dependency-exists surfaces.'
disable-model-invocation: true
user-invocable: true
---

# Find Simplifications

This skill turns a broad "find things to simplify" request into a small set of proven proposals.
Each proposal must remove, fold, or demote real code.
This is guidance, not a checklist.
Follow the code and keep judgment active.
A few well-proven candidates beat a pile of thin guesses.

## 1. Read The Repo Context First

1. Read `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the root `README`.
2. Read the architecture and testing docs if the repo has them.
3. Find the decision records. Common places are `docs/adr/`, `docs/decisions/`, `docs/proposals/`, `.agents/notes/`, and RFC folders.
4. Read the records that cover the area you plan to touch.

A recorded decision protects a design on purpose.
Do not propose to delete a protected design as "easy cleanup".
You may still remove an unused method inside a protected seam.
That removal is fine when it does not collapse the protected design.

Ask the user where a proposal must go when the repo has no proposal folder.
Good targets are a new markdown file under `docs/`, an issue in the tracker, or the PR body.

## 2. What Counts As A Strong Candidate

A strong candidate has proof that the current design costs more than it buys.

- A public method, event, config key, hook, helper, or package has no production consumer.
- Tests or docs are the only consumers, and the pinned behavior is not load-bearing.
- Two representations hold the same fact and must stay in sync by hand.
- An interface forces every implementation to support a method that no caller uses.
- A separate package holds only test, demo, or support code and adds publish or dependency cost.
- A feature is speculative and has no product owner.
- An invariant, rollback path, or special-case test exists only to protect an unused API.
- Hand-rolled code repeats what a healthy package or a language builtin already does.
- The simpler behavior differs a little, but it is still correct and easier to explain.

## 3. What Is Too Thin

Do not open a proposal for these.

- One typo.
- One run of a dead-code tool with no reading of the call sites.
- Removal of a design that a decision record defends, with no new evidence.
- "This looks complex" with no call-site proof.

Small but correct ideas become an inline TODO instead.
See section 9.

## 4. Survey Broadly

Use parallel subagents when the user asks for breadth or for many candidates.
Give each agent one domain.
Require evidence, not guesses.

Useful domains:

- Entry points: CLI, server routes, jobs, and startup code.
- Public API surface: exported types, SDK methods, plugin seams, and events.
- State and lifecycle: sessions, caches, queues, cancel paths, and replay.
- Storage and IO: schemas, migrations, file formats, and wire formats.
- Config and flags: defaults, overrides, and environment variables.
- Build and tooling: scripts, generators, package splits, and CI steps.
- Tests and fixtures: snapshots, generated expected output, and support packages.

Start with the largest production-code files and the largest recent deltas.
Do not stop the survey at the first good candidate.
Simulate the same breadth yourself when subagents are not available.

## 5. Audit Trust And Lifecycle Boundaries

For every defensive copy, freeze, validator, and callback capture, name two things.
Name where the value came from.
Name who owns it next.

Same-process typed calls can usually borrow a readonly value.
Parsers, config loaders, queues, model or tool JSON, files, workers, processes, and wire decoders must own or validate their data.
A test built on a hostile getter, a fake typed object, or mutation after a same-process handoff is a hint.
It hints at a speculative contract, not at a contract you must keep.

For hard async code, draw the ownership graph.
Map each sentinel, readiness promise, cancel path, disposer, and state flag to one owner.
Propose one controller when several mechanisms mirror the same liveness fact.
Keep separate machinery when it protects rollback, callback containment, first-outcome arbitration, worker ownership, or dispose-to-quiet.

## 6. Hand-Rolled Code Versus A Dependency

A new dependency can be a valid simplification.
Ask this of protocol parsers, framers, retry loops, glob matchers, and diff engines.
Does a healthy package or a language builtin already do this job?

Prove such a swap like any other candidate, plus these steps.

1. Read the hand-rolled code and name the exact surface the package covers.
2. List the leftover behavior the package does not cover, and keep it in the proposal.
3. Check package health: maintenance, adoption, and transitive size.
4. Prefer a builtin when the runtime floor of the repo already has one.
5. Check the decision records first, because a recorded seam needs stronger proof.
6. Weigh net deletion: code plus its tests plus its docs, minus the glue that stays.

A wrapper that moves the same complexity is not a win.

## 7. Prove Or Reject Each Candidate

Classify every consumer before you write anything.

- Production corpus: application and library source, runtime scripts, examples that ship, and config loaders.
- Non-production corpus: tests, docs, snapshots, generated expected output, and comments.
- Ambiguous corpus: examples and scripts that may be smoke paths. Read them before you classify them.

Use `rg` first.
Search the exact symbol, event name, package name, config key, and wire string.
Search a method both as `.name(` and as `name(`.
Then read the call sites.

Dead-code tools help but do not prove anything.
Examples are `knip`, `ts-prune`, `vulture`, `deadcode`, and `cargo-udeps`.
They miss public interfaces, dynamic names, docs, and plugin loader paths.

Reject or downgrade a candidate in these cases.

- A production caller exists, so the change is a product decision, not a cleanup.
- A decision record or a hard-won defensive pattern justifies the API, and your evidence does not beat it.
- The removal forces churn elsewhere without cutting the public API or the required behavior.
- The idea is right but tiny. Write an inline TODO instead.

## 8. Write The Proposal

Write one file per durable proposal.
Use the folder and naming rules of the repo.
Use `docs/proposals/yyyy-mm-dd-topic.md` when the repo has no rule.
Get the date from `date +%F`, not from memory.
Put each full sentence on its own line and use relative Markdown links.

Use this structure and adjust it when the idea needs it.

- `# <action-oriented title>`
- `Status: proposed`
- `## Problem`: name the current API, cite the files, and give the consumer evidence. Split production callers from tests and docs.
- `## Proposal`: say exactly what to remove, fold, demote, or rehome. Include tests, docs, README, doc comments, snapshots, and generated files.
- `## What we give up`: state the strongest counterargument in plain words.
- `## Acceptance criteria`: the end state you can observe, plus the checks that must pass.
- `## Risks`: public API changes, behavior changes, future wants, and why the trade is still fair.

Be concrete enough that another engineer can follow the trail.
Do not write "simplify this package".
Fold new details into the existing proposal when one already owns the topic.

## 9. Inline TODO Notes

Use `TODO`, `FIXME`, or `XXX` only for small local cleanups.
Follow the urgency words the repo already uses.

- Tag the smell with a stable name, for example `TODO(double-default)`.
- Say why the change is safe and what action makes it simpler.
- Do not tag a guess.
- Do not tag work that needs a full design decision.

## 10. Retire Superseded Proposals

Do this only when the user asks for it, or when your change makes an old note wrong.
Do not grow every survey into a repo-wide note audit.

1. Find the current owner from shipped code, config, generated catalogs, docs, and newer notes. Dates and titles are hints, not proof.
2. Mark the old note as fully or partly superseded. Any live behavior, contract, durable format, or compatibility duty makes it partial.
3. For a full supersession, move every unique reason, alternative, consequence, and verified result into the current owner.
4. Repair every inbound link. Then delete the old note and its translations together.
5. Search the exact filenames, symbols, config keys, and wire strings again after the edit.
6. Keep partial supersessions cross-linked and current.

An added-then-removed feature is the common full case.
Let the removal note own the history only when all of these hold.

- The feature is gone from code, config, schemas, durable formats, and compatibility paths.
- No current doc presents it as available.
- No test treats it as supported behavior.

Keep the reason the feature existed, why that reason died, the alternatives, the lost capability, and the conditions for a comeback.
Reject the merge when the removal covers only one transport, default, or view of the feature.
Reject it also when stored data or compatibility code survives.

## 11. Fold Another PR Or Branch

Diff the other branch against the trunk, not against your branch.
This shows its own contribution.

- Port the non-overlapping notes and TODOs that meet the bar.
- Merge overlapping material into the note that owns the topic.
- Do not port a duplicate or a weaker idea just to raise the count.
- Update the PR body so reviewers see the true scope.
- Close the other PR only when the user asks you to.

## 12. Validate And Report

Find the check commands in the repo itself.
Look at `package.json` scripts, `Makefile`, `justfile`, and the CI config.

1. Run the lint task for docs-only work.
2. Run `git diff --check`.
3. Run the type check and the tests when you touch code or comments.
4. Pick any other check that the outgoing diff touches.

Summarize this in the PR body.

- How many proposals and inline notes you added, merged, kept, or deleted.
- The areas you surveyed.
- What you left out on purpose.
- Which checks passed.

Keep the PR in draft while the survey grows.
Mark it ready when the candidate set, the review replies, and the checks are settled.
