# Triage and handoff

The run produced a report. This phase turns it into tracker tickets and hands the fix work to another agent. It is deliberately a **separate agent and step** - often a cheaper model - because it is mechanical, and because the person who ran the tests should not also be the person who silently reinterprets them.

The report is the **sole source of truth** for this phase. The triage agent does not re-run tests, does not read the giant `runs/` artifacts (it references their paths), and does not add findings the report did not make.

## Create-vs-comment, without inventing ids

The dangerous move is a weak agent fabricating a ticket id or filing a duplicate. Constrain it:

- **Verify before you comment.** For any existing tracker id the report names, fetch it first. If it does not exist, **stop on that item and record NOT-FOUND** - never invent, never guess a nearby number.
- **Pull the epic's children once.** Get the current child list of the parent epic; that list is the *only* basis for deciding new-ticket-vs-comment.
- **Dedup by keyword against that list.** A finding whose theme clearly matches an existing child becomes a comment on it, flagged `possible-dup`, not a new ticket. When genuinely unsure, create but flag it - a flagged possible-dup is cheap to merge; a lost finding is not.
- **New tickets are children of the epic**, inheriting its team/project. Resolve the epic first to get those.
- **Negative results are worth a comment.** A tier-D issue that did *not* reproduce gets a "not reproduced this round, evidence at `<path>`" comment - it stops a fixer wasting time on a ghost.
- **Do not file environment/runbook blockers as product tickets.** Surface them only in the handoff so nobody chases them.

## Ticket / comment content

Copy facts from the report; add no new inference. Use a fixed template so a weak agent cannot wander:

```
Title (new): [<run-tag>] <one-line symptom>
Body:
- Symptom: <report's words>
- Reproduced: <count + scenarios>
- Evidence: <runs/ path(s)> + <entity id(s)>   (reference paths; never paste blobs)
- Suspected root cause: <from report>
- Source: <report file> <F# or section>
- Severity/tier: <A-guard regression / B / C / D / new-high-sev>
```

Tracker-tool hygiene: use real newlines (not literal `\n`); omit fields the tool rejects (some reject arbitrary icons/emoji); **do not set a due-date if the tool cannot later clear it**; do not touch unrelated issues' status/assignee. And, as everywhere: **no tokens or connection strings** in any ticket.

## Group by root cause before handing off

The report's FAILs are symptoms; the fixer should work by **root region**, not ticket-by-ticket. In the handoff, cluster related findings under a single suspected cause (e.g. "these four symptoms all stem from one anchoring gap"; "these two are one unit-conversion bug plus its swallowed write"). This turns N tickets into a handful of fix sites.

## The peer handoff

Hand the grouped work to a fixer agent (typically a stronger model) over the peer channel. The handoff message carries:
- A pointer to the report and the `runs/` evidence dir (paths, not contents).
- The **manifest**: every finding with its action (CREATE / COMMENT / NOT-FOUND / DUP) and the resulting ticket id + url.
- A **priority order**, P0 first - lead with anything that blocks a whole funnel (a flow that cannot proceed past step one, a defect that suppresses an entire class of results) and anything touching money or data loss.
- The **root-cause groups**, so the fixer fixes by region.
- The **environment blockers**, explicitly flagged "not product bugs - do not fix in code."

Before sending: confirm the target peer is actually reachable and working in the right repo (list peers, check its working dir). If it is not, stop and report - do not fire a handoff into the void. Use a clear placeholder for the peer id (`<FIXER_PEER_ID>`) that the human fills in.

## Authority note

These are distinct grants, and they do not transfer:
- **Ticketing authority** (this phase writes to the tracker) does **not** grant the fixer authority to commit, push, or merge.
- The fixer needs its own confirmation before it starts changing and shipping code. The handoff **queues** the work; it does not authorize the merge.
- Grants are session-bound. A handoff across sessions must restate the authority model, not assume the successor inherited it.

After the handoff is delivered, this phase stops. It does not start fixing, and it does not wait to do more - the fixer owns the next step.
