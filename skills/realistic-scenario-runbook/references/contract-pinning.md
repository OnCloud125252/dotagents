# Pinning the wire contract and invariants

The single largest source of false verdicts is a runner asserting against a contract that is **remembered** or **inherited from a stale doc** instead of **read from the code that is actually deployed**. Close that gap before writing any assertion.

## Why pin, and pin every round

- Shapes drift. An event count, an enum, a default, a field name: any of these can change between the round you designed for and the round you run. A single drifted constant turns a green run red (or worse, hides a real regression behind a green).
- The runner is often a weaker model or a fresh session with no memory of the design. It cannot "just know" the framing. Whatever is not pinned, it will guess - and guess confidently.
- Prior-run docs are a map, not the territory. Treat them as leads to verify, never as truth to copy.

**Recalibrate the pinned constants at the start of every round**, against the exact revision that is deployed to the target environment. Record that revision (branch + commit) at the top of CONTRACTS.md.

## The single CONTRACTS artifact

Produce one file - `kit/CONTRACTS.md` - that is the **sole API truth** for the whole run. The runbook and every subagent point at it. If a fact is not in CONTRACTS.md, the runner must not assume it.

Rules for CONTRACTS.md:
- Every entry is **source-pinned**: quote or reference the file and symbol it came from, so it can be re-verified. Prefer a `path:symbol` anchor over prose.
- No secrets, no real ids, no sample tokens. Contracts are shapes and rules, not data.
- State the **deployed revision** it was pinned against, and the date.
- When a constant has a known tolerance ("baseline is N, a run may legitimately emit N+1"), state the tolerance, not just the value. An off-by-one that is expected must not read as a failure.

## The what-to-pin checklist

Walk this list against the source; put each answer in CONTRACTS.md.

- **Transport framing.** How are streamed responses framed? A common trap: one endpoint emits every frame under a single event name with a `type` discriminator in the JSON body, while another endpoint uses the frame's event name *as* the type. These parse differently; a parser written for one silently mis-reads the other. Pin the exact framing per endpoint.
- **Terminal signals.** What marks success, what marks error, what marks "done"? What field carries the failure reason, and what are its allowed values?
- **Enumerations and discriminators.** Item/entity kinds, status values, category tags. Pin the closed set. If the runner expects a kind that does not exist ("there is no `hotel` type; a hotel is an entity with `category=HOTEL`"), it will assert nonsense.
- **Counts and step budgets.** Any "expected number of steps/events/stages" the runner uses as a health check. Pin the current number **and its legitimate tolerance**. This is the constant most likely to have drifted since the last round.
- **Cross-store invariants.** The rules that must hold *across* systems and that the HTTP API may not expose. Example shape: a "see-side" value in a CRDT/document store must equal a "book-side" value in a transactional store, and the linking id is not returned by the HTTP API - so checking it **requires read-only datastore access**, not just the API. Pin the invariant, both sides, and the exception cases (e.g. "the 1:1 rule applies to kinds X and Y but not Z, which legitimately binds many").
- **Coordinate / unit conventions.** Axis order (lng/lat vs lat/lng), currency minor vs major units, time zones and whether timestamps are local or UTC. Unit confusion produces spectacular false readings (a 100x price, a transposed location).
- **Identity and correlation.** Which ids correlate a request across logs/traces/stores, so evidence can be joined later.
- **Idempotency and cleanup surface.** The exact call that deletes a created entity, and whether deletion cascades to dependent rows in other stores (often it does not - record that, it becomes a cleanup and a data-hygiene finding).

## Environment and datastore traps

Pin these explicitly, because getting them wrong wastes a whole scenario or leaks a secret:

- **A connection string that looks like one store but is another.** An env var named like a generic database URL may point at a different engine entirely (e.g. a name suggesting one datastore actually holding a VPC-only SQL database you must not touch). Pin *which* store each handle is, which are reachable from where the run executes, and which are off-limits. Never run a query blind against an unpinned handle.
- **Permission scope of the test identity.** The token may be valid for some routes and forbidden on others (e.g. can read collaboration state but cannot presign uploads). A 403 there is an **environment blocker, not a product defect** - pin it so the runner records it correctly instead of filing a bug.
- **Which base endpoint is which.** The env may carry more than one URL (a local one, a shared beta one). Pin the exact one to target; do not assume the first variable found.
- **Readiness detection.** If a custom logger suppresses the framework's "server started" line, tailing the log for a start marker hangs forever. Pin the real readiness probe (curl the endpoint), not a log grep.

## Output of this phase

A CONTRACTS.md that a stranger could hold next to the API and use to tell right from wrong, with no access to your memory - plus, baked into the runbook's decision tables, any constant the runner must compare against so it never has to recall or recompute it.
