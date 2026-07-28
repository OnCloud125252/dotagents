# The running tally and the final report

Two artifacts, two jobs. The **tally** is written *during* the run so a crash costs one scenario, not the whole effort. The **report** is the rollup at the end, precise enough that someone can open tickets from it without re-running anything.

## The running tally

The orchestrator appends to `tally.md` as each subagent returns. It is terse and evidence-first; full detail lives in the report and in `runs/`.

Per scenario, record:

- The scenario id and a one-line description, and a DONE/cleaned marker.
- Each assertion's verdict (PASS/FAIL/BLOCKED/KNOWN-OPEN) with the **grade** and a one-clause reason.
- The **evidence**: `runs/` artifact filename(s) + entity id(s).
- Whether a FAIL was reproduced, and the orchestrator's independent confirmation.
- Timings (first-byte, total, event counts).
- The ids created and their cleanup result (removed + verified-gone).

Header the tally with the frozen run parameters so every entry is interpretable standalone: the date literals, the window-start timestamp, the deployed revision, and confirmation that startup checks passed.

Because it accrues live, the tally is also the recovery point: if the run dies at scenario 12, you resume at 12, not at 1.

## The final report

Structure it so a reader goes summary -> matrix -> failures -> open items -> realism -> proof, and can stop at whatever depth they need.

### 1. Header / provenance

Executor model(s) and architecture (orchestrator + N serial subagents), the kit used, the deployed revision, the base environment, the frozen date literals, the window-start timestamp, and a line confirming startup checks all passed and no secrets appear anywhere in the document.

### 2. Executive summary

The verdict in a paragraph, then bullets grouped by tier: A-guard regressions, B confirmations/failures, C known-open behaviours, D reproductions, plus any **new defect discovered that was not on the input list** (these are high-value - a run that only checks the list misses the ones nobody filed yet), and the environment/runbook blockers.

### 3. The assertion matrix

The full (scenario x assertion) table from `references/scenario-design-and-tiers.md`, every row carrying a verdict, tier, and evidence pointer.

### 4. The FAIL list

One entry per confirmed FAIL, each self-contained:

```
### F<n> - <one-line symptom> (<tier>, <severity>)
- Symptom: <what is wrong, concretely>
- Reproduced: <count + which runs>; orchestrator re-verified via <artifact>
- Evidence: <runs/ artifact(s)> + <entity id(s)>
- Suspected root cause: <from the evidence, not a guess>
- Draft ticket: <text suggestion only - filing happens in triage, not here>
```

Two independent pieces of evidence per FAIL (the original run and the rerun). A FAIL without a reproduction and an orchestrator re-check is a suspicion, and is labelled as one.

### 5. KNOWN-OPEN ledger (tier C)

A table of each still-open issue and how it behaved this round, with evidence. This is what keeps the tracker honest.

### 6. New-defect reproduction table (tier D)

Per newly-reported defect: reproduced / not-reproduced, with the API-level evidence either way.

### 7. Latency + cleanup proof

- The latency table (first-byte, totals, event counts) against any latency criteria, and whether any run breached a hard ceiling.
- **Cleanup proof**: the post-window sweep result (must be zero), and confirmation every created entity was removed and verified gone. Record any non-cascading delete (dependent rows left in another store) as a data-hygiene finding.

### 8. Realism findings

The cross-cutting, often-highest-signal section: systematic artifacts that span scenarios, recurring anchoring/placement gaps, silent-drop patterns, degradation that was not surfaced. These frequently do not map to any single existing ticket and become the most important new work.

### 9. Blockers vs defects (appendix)

Every BLOCKED assertion, with its cause and whether it is an environment/permission issue or a runbook-design gap - explicitly *not* a product defect - plus how to unblock next round. Keeping this separate stops a later reader from chasing a non-bug.

## Discipline for both artifacts

- **Evidence or it did not happen.** Every claim cites a `runs/` path + an id. No prose-only verdicts.
- **No secrets, ever.** Tokens and connection strings never appear, not even redacted-with-a-hint.
- **Plain, auditable language.** State what passed, what failed, what was skipped. If something was not tested, say so; do not imply coverage that did not occur.
