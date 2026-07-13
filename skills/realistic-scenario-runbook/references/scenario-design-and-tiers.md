# Scenario design, tiers, and realism

A scenario is a small story: a real user with a real goal, driving the product through several turns, ending in a state you can check and then clean up. This is where "realistic" is won or lost.

## Anatomy of a scenario

Every scenario has four parts, in order:

1. **Setup / create.** Establish the entity the way a real user would - usually by driving the product's own create flow with a natural-language brief, not by seeding the database directly. If the scenario tests a later stage, still create the earlier state through the real flow so the entity is realistic.
2. **Drive as a real user.** Issue the turns a person would: phrased naturally, sometimes changing their mind, sometimes vague, sometimes with a typo. The point is to exercise the *intake and reasoning*, not to hand the system a clean machine payload.
3. **Verify - structure and realism.** Check the wire contract held (structure, invariants, see contract-pinning) **and** that the result is realistic (below). A scenario passes only if both hold.
4. **Cleanup + prove gone.** Delete every entity created, read back a 404, and let the orchestrator's post-window sweep confirm zero residue. Note any cascade the delete does *not* cover (e.g. dependent rows in another store) as a data-hygiene finding, not a failure, unless a clean cascade was the thing under test.

## Write scenarios for a weak runner

- **One clear goal per scenario**, with the assertions listed as a table the runner fills in - not prose it must interpret.
- **Bake the comparison values in.** If a check compares against a pinned constant, put the constant in the scenario's decision table so the runner never recalls or recomputes it.
- **Give the exact turns** to send, and the exact kit command per step. Leave nothing to "figure out the right request".
- **State the expected verdict and the tolerance** for each assertion, so PASS/FAIL is a lookup, not a judgment call.

## The tier taxonomy

Grade every assertion into one of four tiers. The tier sets the stakes and what a FAIL means.

- **Tier A - regression guard.** Something that was previously broken and is now fixed, or an invariant that must always hold. A FAIL here is the most serious outcome: a regression. These are your P0 tripwires.
- **Tier B - done-but-unverified.** Work marked done in the tracker but never verified end-to-end against a real environment. This is usually the **main target** of the run - the reason it exists. A FAIL means "marked done, is not."
- **Tier C - still-open.** Known-open issues. You are not trying to fail the run on these; you **probe and record** the current behaviour (a KNOWN-OPEN ledger entry with evidence), so the tracker reflects reality and a later fixer has a fresh repro. A C behaving badly is expected, not a run failure.
- **Tier D - newly-reported defect.** A freshly-filed bug you are trying to **reproduce**. Outcome is reproduced (with evidence and a repro count) or not-reproduced (also with evidence - a negative result is valuable and prevents wasted fixing).

Also mark **out-of-scope / environment blockers** explicitly so they never masquerade as either pass or fail.

## The realism catalog

HTTP 200 + schema-valid is necessary, not sufficient. A response is only correct if it is also feasible in the domain. Check the applicable ones:

- **Temporal feasibility.** Nothing scheduled before it is possible (an activity before the arrival that enables it; a checkout before checkin; an event outside its opening window). Held/committed constraints set hard bounds the plan must respect.
- **Spatial feasibility.** No impossible jumps (a same-day hop between far-apart places with no transit that allows it); entities placed in the correct locale (the branch in the right city, not a same-named one elsewhere).
- **Capacity and pacing.** Volume that suits the actor (a plan for a small child is not packed like one for solo adults); counts and quantities that match the party.
- **Domain constraints honoured.** Closed days avoided, prerequisites respected, quantities within limits.
- **Honest degradation.** When the system cannot satisfy something, it says so - the shortfall is surfaced on the wire (an "unresolved" warning, a skip reason) and in the user-facing message, not silently dropped. Silent loss of a real, explicit user request is a defect even when the response looks clean.
- **Consistency across repeats.** The same brief run twice yields materially consistent output (same rough scope, cities, counts, price magnitude). Wild variance is a finding.
- **Change-of-mind handling.** When the user reverses an earlier constraint, the old constraint is fully purged, not left lingering.
- **Truthfulness of confirmations.** What the system *says* it did matches what it *persisted*. A reply claiming success over a state that did not change ("false success") is among the worst defects - it hides data loss behind a green message.
- **Input hygiene.** Typos do not spawn invented entities; past or nonsensical dates are challenged or corrected, not silently accepted.

Realism findings that do not map to a single tracked issue (a systematic stray value across many scenarios, a recurring anchoring gap) go in a dedicated **realism-findings** section of the report - they are often the highest-signal output of the whole run.

## The assertion matrix

Record verdicts as a matrix - one row per (scenario, assertion), columns for verdict, tier, and evidence. Legend: PASS / FAIL / BLOCKED / KNOWN-OPEN. The evidence column is a `runs/` artifact path plus the entity id, so any row can be re-verified from disk.

```
| scenario | assertion                    | tier | verdict | evidence (runs/ + id) |
|----------|------------------------------|------|---------|-----------------------|
| <S1>     | <what must hold>             | A    | PASS    | <artifact> / <id>     |
| <S1>     | <realism: temporal>          | A    | FAIL    | <artifact> / <id>     |
| <S2>     | <known-open behaviour>       | C    | KNOWN-OPEN | <artifact> / <id>  |
```
