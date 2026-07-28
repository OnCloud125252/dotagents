---
name: realistic-scenario-runbook
description: Author and run a realistic, multi-scenario end-to-end test runbook that simulates a real user driving a product through its live API, then triage the results into tracker tickets and hand the fixes to another agent. Trigger when the user asks to build a scenario suite / regression runbook that verifies a batch of "done" fixes or probes an epic's sub-issues against a real environment - each scenario doing create -> verify -> cleanup, graded into tiers, run by a fleet of isolated subagents, and rolled up into a report. This is the multi-scenario, tiered, subagent-orchestrated sibling of a single-flow smoke test; reach for smoke-test instead when the user only wants one flow exercised once.
disable-model-invocation: true
---

# realistic-scenario-runbook

Build a runbook that a **separate, possibly weaker, agent can execute without hallucinating**, that drives a product end-to-end as a real user would (natural-language turns through the live API), proves each fix or probes each open defect, cleans up after itself, and produces a report precise enough to open tickets from. Then optionally triage that report into a tracker and hand the fix work to a peer agent.

The deliverable is not a test script. It is a **runbook + a validated tool kit + an execution architecture**, engineered so that the gap between "what the author knew" and "what the runner does" is closed in advance.

## When to use

Use this when all of these hold:
- The target is a **live environment** (a shared beta/staging), not a mock, so tests write real data and must self-clean.
- There is a **batch** of things to verify: a set of "fixed" issues to regression-guard, an epic's sub-issues to probe, or newly-reported defects to reproduce - not a single endpoint.
- Verification requires **domain realism**, not just HTTP status: the output is only correct if it also makes sense in the problem domain (feasible schedule, sane geography, honest error surfacing, consistency across repeats).
- The run will be handed to **another agent** (a cheaper model, a fresh session, a subagent fleet) that was not present for the design.

Prefer the `smoke-test` skill instead when the user wants one flow exercised once, inline, with no tiering, no fleet, and no report.

## Inputs

- **Environment handle**: an env file (sourceable) holding a base endpoint URL and an auth token. Both are secret-bearing.
- **The verification set**: the issues/behaviours to test, usually from a tracker epic and/or a prior run's report.
- **Source access**: the product's source tree, to pin the wire contract and invariants (see `references/contract-pinning.md`).
- Optional: read-only datastore access to check invariants the HTTP API does not expose.

## The pipeline at a glance

```
author phase        run phase                         output phase
-----------         ---------                         ------------
pin contracts   ->  orchestrator: startup checks  ->  running tally (accrues live)
build tool kit  ->  dispatch 1 subagent / scenario ->  final report
design scenarios    (isolated, strictly serial)   ->  triage -> tracker tickets
+ tiers + fixtures  verify (incl. realism)         ->  peer-handoff to a fixer agent
                    self-clean + prove gone
```

## The seven principles

1. **Every scenario is create -> verify -> cleanup, and self-cleaning.** A scenario that runs against a shared environment must delete everything it created and *prove* it is gone (read-back 404 + a post-window sweep that matches zero). Runs are idempotent and leave no residue. See `references/scenario-design-and-tiers.md`.

2. **Simulate a real user, not an API fuzzer.** Inputs are natural-language turns as a real person would phrase them; verification accounts for real-world domain conditions. Realism is itself a pass criterion - a response can be HTTP 200, schema-valid, and still *wrong* because it is infeasible in the domain. See the realism catalog in `references/scenario-design-and-tiers.md`.

3. **Pin the wire contract and invariants from source before writing any assertion.** Do not trust memory or a prior run's doc; read the code and pin framings, enums, counts, and cross-store invariants into one CONTRACTS file that is the single API truth. Recalibrate every round - counts and shapes drift between runs. See `references/contract-pinning.md`.

4. **Give the runner deterministic, pre-validated tools, not room to improvise.** A zero-dependency CLI harness (with a `selftest`), pre-generated fixtures, and mechanical decision tables. Validate the tool against the live API before trusting a single verdict it emits. Never print secrets. See `references/harness-and-fixtures.md`.

5. **Isolate but serialize.** One subagent per scenario so its noisy output never pollutes the orchestrator's judgment; never two at once, because a shared token/quota/log make concurrency both flaky and unattributable. Pass **computed date literals**, not "recompute D+45", so every subagent agrees regardless of wall-clock. See `references/orchestrator-subagent.md`.

6. **Grade every assertion into a tier, and re-check verdicts adversarially.** A = regression guard (was fixed, must stay fixed); B = done-but-unverified (the main target); C = still-open (probe and record, do not fail the run); D = newly-reported defect (reproduce). A FAIL is rerun once and re-verified against raw evidence before it is called a FAIL; a couple of PASSes are spot-checked. Every verdict cites an evidence artifact + an entity id. See `references/scenario-design-and-tiers.md`.

7. **Output is a live tally, then a report, then triage and handoff.** The tally accrues per-scenario as you go so a crash loses one scenario, not the run. The report carries an assertion matrix, a FAIL list with repro + evidence + suspected root cause, a KNOWN-OPEN ledger, a realism-findings section, and cleanup proof. A separate triage step turns the report into tracker tickets (create-vs-comment mechanically, never inventing an id) and hands the grouped fix work to a peer agent. See `references/report-and-tally.md` and `references/triage-and-handoff.md`.

## Hard rules (apply to every phase)

- **Secrets never surface.** Tokens and connection strings are read from the env, used, and never printed, logged, or written into a report or ticket. The harness reads them from the environment and echoes nothing.
- **No product-code changes during a run.** A verification run reads and exercises; it does not edit source, commit, push, or flip feature flags. Fixing is a later, separate phase owned by a different agent.
- **Deletion is `trash`, never `rm`**, and only of artifacts the run itself created.
- **A blocked assertion is not a failed one.** Distinguish product defects from environment/permission/runbook blockers; record blockers separately so nobody chases a non-bug.
- **Every load-bearing claim is re-verifiable.** Cite the run artifact and the entity id; a reader must be able to re-derive the verdict from disk.

## References

Load these on demand; each is self-contained.

| Reference | Covers |
|---|---|
| `references/contract-pinning.md` | Pinning the wire contract + invariants from source; the what-to-pin checklist; the single CONTRACTS artifact; environment/datastore traps |
| `references/harness-and-fixtures.md` | The zero-dep CLI harness command surface + design rules; validate-before-trust; deterministic future-dated fixtures |
| `references/orchestrator-subagent.md` | The isolate-but-serial dispatch loop; orchestrator vs subagent duties; the subagent prompt contract; date literals; FAIL re-check |
| `references/scenario-design-and-tiers.md` | Scenario anatomy; the A/B/C/D tier taxonomy; the realism criteria catalog; the assertion matrix format |
| `references/report-and-tally.md` | The running tally; the final report structure and templates |
| `references/triage-and-handoff.md` | Turning the report into tracker tickets; root-cause grouping; peer-handoff to a fixer agent |

## Kit layout this skill produces

```
<effort-dir>/                      # a durable handoffs dir, not a scratchpad
  runbook.md                       # the agent-runnable scenario doc (sections mirror the references)
  kit/
    harness.<ext>                  # zero-dep CLI: gen/chat/read/checks/list/remove/... + selftest
    fixtures.sh                    # deterministic, future-dated fixture generator
    fixtures/                      # generated inputs + their date literals
    CONTRACTS.md                   # the single pinned API truth
    runs/                          # raw per-run artifacts (large; referenced, never inlined)
  tally.md                         # accrues live during the run
  report.md                        # final rollup, precise enough to open tickets from
```
