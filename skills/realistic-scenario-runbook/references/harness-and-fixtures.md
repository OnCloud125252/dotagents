# The harness and fixtures

The runner should never hand-craft a request, hand-parse a stream, or eyeball a JSON blob to reach a verdict. Give it a **tool** that does the mechanical work deterministically, and **fixtures** that are ready before the run starts. The less the runner improvises, the fewer verdicts it invents.

## Harness design rules

- **Zero dependencies.** A single script in the runtime already present (no install step, no lockfile, no network fetch of packages). It must run in a fresh worktree or a bare subagent with nothing set up.
- **Reads secrets from the environment, prints none.** The base endpoint and token come from the env file; the harness sources them and echoes nothing. No secret ever reaches stdout, a log, or an artifact.
- **One base endpoint, pinned.** Hard-code the target base (the pinned one from CONTRACTS.md), so a subagent cannot accidentally aim at the wrong environment.
- **Handles every transport framing the product uses.** If the product streams two different framings (see contract-pinning), the parser detects and handles both, rather than assuming one.
- **Reconstructs the domain model deterministically.** If verdicts depend on structure the API returns in a raw or denormalized form (items grouped under day separators, ordering by position, nesting), the harness reconstructs that model once, the same way every time, so two runs of the same input compare cleanly.
- **Emits verdicts as PASS / FAIL / INFO lines**, machine-greppable, each naming the check. The runner reports these; it does not re-derive them from raw output.
- **Writes raw artifacts to `runs/`** (full SSE dumps, read snapshots, datastore reads) and prints only a compact digest. Raw stays on disk to be referenced; it never floods the runner's context.
- **Idempotent and re-runnable.** Re-running a command with the same inputs is safe.

## A typical command surface

Adapt the verbs to the product; the shape generalizes. Each command does one thing and prints a digest + an artifact path.

| Command | Purpose |
|---|---|
| `selftest` | Self-check the harness end to end with no side effects; must pass before the run trusts it |
| `check` | One cheap authenticated call (health / list); confirms token + endpoint before real work |
| `gen` / `create` | Drive the primary "create" flow from a body file; capture the stream to `runs/` |
| `chat` / `turn` | Drive one conversational turn against an existing entity |
| `read` | Fetch + reconstruct the domain model for an entity; write the snapshot to `runs/` |
| `checks` | Run the mechanical assertion battery over a read snapshot; emit PASS/FAIL/INFO |
| `versions` / `revert` / `approve` | Exercise version-control / undo / approval surfaces |
| `list` / `remove` | Enumerate and delete entities - the cleanup surface |
| `offers` / `upload` | Any auxiliary provider/media surface a scenario needs |

Design the assertion command (`checks`) so its FAIL lines are **self-explaining**: not "out-of-window item", but "out-of-window item `<id>` @ `<timestamp>`", so the runner sees *which* datum failed without opening the raw artifact.

## Validate before you trust

A harness that emits confident PASS/FAIL is worse than none if it is silently wrong. Before the run relies on it:

1. Run `selftest` - it must pass.
2. Make one **live** call against the real environment (`check` returning success) - proves token, endpoint, and framing parser agree with reality.
3. Sanity-check one known-good and, if possible, one known-bad input, and confirm the verdict matches expectation.

Only after this does a harness verdict count as evidence.

## Fixtures: deterministic and future-dated

Scenarios that need uploads or inputs with dates should not generate them mid-run (non-deterministic, and a weak runner will fumble it). Pre-generate them:

- **Deterministic.** Same generator, same bytes, every time. Do not use AI to produce fixture content; compute it. (Compute dates and ids programmatically, never free-hand them.)
- **Future-dated, relative to a frozen "today".** Anything time-sensitive (a booking, a ticket, an event) must sit in the future relative to the run, or realism checks will reject it for the wrong reason. Emit the chosen date literals to small sidecar files (`DEP_DATE`, `RET_DATE`, ...) so both the fixture and the runbook reference the *same* value.
- **A mix of clean and noise.** Include a valid fixture and a deliberately-irrelevant one, if a scenario tests "does it correctly ignore the irrelevant attachment".
- **Self-describing.** The fixture's visible content states what it is, so a human reviewing an artifact can tell at a glance.

## Where the kit lives

Keep the harness, fixtures, CONTRACTS, and `runs/` together in the effort's durable directory (a handoffs dir, not a session scratchpad - a scratchpad is lost when the session closes, and the kit must outlive any one session). The `runs/` directory can grow large; it is referenced by path from the tally and report, never pasted in.
