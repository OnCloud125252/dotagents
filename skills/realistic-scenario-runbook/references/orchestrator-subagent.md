# Orchestrator and subagents: isolate but serialize

Two constraints that look like they conflict, but do not:

- **Isolate.** One scenario produces a flood of stream dumps, read digests, and datastore output. If that all lands in the context that is judging every scenario, it pollutes judgment and blurs later verdicts. So each scenario runs in a **throwaway subagent context**, used once and discarded.
- **Serialize.** Concurrency is unsafe here: a **shared user token** may be serialized server-side (concurrent creates can 429), a **shared provider/LLM quota** amplifies flakiness, and a **single global event log** cannot attribute two runs happening at once. So **never run two subagents at the same time**.

The resolution is one line: **isolate but do not parallelize.** One subagent per scenario, dispatched strictly one at a time.

## Division of labour

**The orchestrator (main agent) does only:**

- Startup checks (harness `selftest`, one live `check`, confirm the environment is clean, confirm any global flags are in the expected state).
- Compute the shared **date literals** once (today, tomorrow, +30, +45, the window-start timestamp) and freeze them.
- The dispatch loop: hand scenario N to a fresh subagent, wait for its structured verdict, then hand out scenario N+1. No overlap.
- Cross-scenario work that genuinely needs the whole picture: the final cleanup sweep, the latency table assembled from every subagent's timings, and reconciling any shared-state findings.
- FAIL discipline (below) and the final report.

**Each subagent does exactly one scenario:**

- Reads the runbook rules, the relevant scenario section, and CONTRACTS.md first.
- Runs the scenario create -> verify -> cleanup using only the kit.
- Leaves raw output in `runs/`; returns only a compact verdict.
- Cleans up what it created and proves it gone before returning.

## The subagent prompt contract

Every dispatch must hand the subagent everything it needs to run blind, because it shares none of the orchestrator's memory. Include:

- **Read-first pointers**: the runbook rules section, its one scenario, CONTRACTS.md.
- **The date literals, as values** - not "recompute +45 days". A subagent runs in a separate shell; a value it recomputes at 23:59 disagrees with one computed at 00:01. Passing the frozen literal makes every scenario's dates provably identical regardless of wall-clock. Determinism over convenience.
- **Working directory and the exact kit commands** it may call.
- **Any prerequisite entity id** produced by an earlier scenario it depends on.
- **The tool allowance** (the kit; read-only log/trace access if useful; nothing that edits product code).
- **The return format**: a compact structured verdict - per-assertion PASS/FAIL/BLOCKED/KNOWN-OPEN, the evidence artifact path + entity id for each, cleanup result, timings, and any residue it could not clean. Large JSON stays in `runs/`; the verdict references it.

## Shared-state scenarios go in one subagent

If two scenarios operate on the *same* created entity (a build-up flow and a teardown flow over one trip/order), running them in separate subagents would force live state to be threaded across agents. Put them in the **same** subagent instead, run in sequence. Isolation is per-unit-of-work, and their unit of work is shared.

## FAIL discipline and PASS spot-checks

- **Every FAIL is earned twice.** A subagent that reports FAIL triggers a re-run - a fresh subagent repeats the scenario as-is. Only if it fails again, and the orchestrator can confirm the failure against the raw artifact in `runs/`, is it recorded as a FAIL. This kills plausible-but-transient false failures.
- **Spot-check the greens.** The orchestrator independently re-derives a couple of PASS verdicts from raw evidence. A run where nobody checked the passes is a run that trusted a possibly-broken harness.
- **Blocked is its own bucket.** If a scenario cannot run for an environment/permission/runbook reason, it is BLOCKED, not FAIL, and the blocker is recorded so it can be fixed out of band (see report structure).

## Aggregation the orchestrator owns

- **Latency table**: collected from each subagent's reported timings (first-byte, total, event counts), compared against any latency criteria.
- **Cleanup sweep**: after all scenarios, a single "list everything created since the window-start timestamp" that must match **zero**. This is the run-level proof of no residue, independent of each subagent's own read-back.
