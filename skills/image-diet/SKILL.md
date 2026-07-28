---
name: image-diet
description: >-
  Progressively shrink a JavaScript/TypeScript project's container (Docker/OCI)
  image through a staged pipeline, letting the user choose how aggressive to get
  by deciding where to stop. Use this whenever the user wants to reduce, slim,
  shrink, or optimize a Docker/container image size for a Node, Bun, or Deno
  app - or complains an image is "too big", "bloated", slow to pull/push/deploy,
  or wants a smaller final image, leaner Dockerfile, or trimmed node_modules.
  Trigger even when they don't say "Docker" explicitly (e.g. "my API image is
  1.3GB", "make the build smaller", "縮小 image", "image 優化"). Detects the
  runtime/package-manager/bundler and adapts each step; verifies every change by
  building and exercising the app before moving on.
---

# image-diet — progressive container-image slimmer for JS projects

## What this does and why it's shaped this way

Container images for JS apps are usually far bigger than they need to be, and the
savings live at very different risk levels: some are free (unused apt recommends),
some are large but need care (swapping a fat native tool), and some are dramatic
but touch code (shipping only the node_modules a bundle actually reads). A single
"optimize it" pass either leaves money on the table or ships a change the user
didn't understand.

So this skill runs a **fixed ladder of stages, ordered by ascending risk**, and
lets the user **escape after any stage** once they've seen its real measured
result. The escape point *is* the intensity dial. Two invariants make that dial
trustworthy:

- **Measure and verify every stage before asking to continue.** Cheap stages get
  a boot smoke test; risky stages re-run the app's real capabilities (render a
  PDF, transcode a clip, run the migrator). Image-only breakage - a data file the
  runtime reads, an unbundled entrypoint's dependency - is invisible to unit
  tests, so you must exercise the actual behaviour.
- **One stage = one commit.** Escaping just stops; a stage that regresses or fails
  verification is reverted without losing earlier wins.

**Never touch staging or production.** Changes you can't fully verify locally
(storage/DB round-trips) are applied and flagged for a human staging smoke-test,
not driven against live infra.

## Prerequisites

- `docker` (or a compatible builder) available and running.
- A target Dockerfile. If none exists, Stage 1 can author a sane multi-stage one
  first.
- The project's install completed (so native deps can be scanned).

## The ladder at a glance

| # | Stage | Touches | Risk |
|---|---|---|---|
| 1 | Build hygiene (`.dockerignore`, multi-stage, prod-only install, apt/apk no-recommends + clean) | Dockerfile | very low |
| 2 | Dependency diet (dead deps, dev→devDeps, asset prune, drop build-only files) | package.json + Dockerfile | low |
| 3 | Bundle the app (single-file bundle so runtime needs little of node_modules) | build pipeline | low-med |
| 4 | Lean native tools (fat apt tool → static binary / lean lib) | Dockerfile + small code | med |
| 5 | Base image swap (debian-slim → alpine/musl, gated on no glibc-only deps) | Dockerfile | med |
| 6 | Runtime built-ins (heavy lib → runtime built-in / lighter alt) | runtime code | med-high |
| 7 | Runtime closure (ship only the node_modules the bundle + entrypoints read) | Dockerfile + prune script | high |

Detection **skips** stages that don't apply (no fat native tool → skip 4; no
heavy swappable lib → skip 6). It never reorders - the ascending walk is what
makes "where I stopped" a legible intensity choice.

Read `references/stage-N-*.md` only when you reach stage N. Each follows the same
template: when to run/skip, adapt-by-detection, apply, risk & impact, verify,
portable gotchas.

## Step 1 — Onboarding (once)

1. **Detect.** Run `scripts/detect-project.mjs` and read the JSON
   (`runtime, pkgManager, bundler, dockerfiles, baseImages, nativeDeps,
   glibcRiskDeps, notes`). See `references/detection.md` for interpreting it and
   manual fallbacks. If there are multiple Dockerfiles, ask which image to slim.

2. **Baseline.** Build the current image and record size + the dominant layers:
   `scripts/measure-image.sh -f <dockerfile> -t <tag>:baseline`. This is the
   number every later stage is measured against.

3. **Declare capabilities and build probes.** This is the safety backbone - do
   not skip it. Infer a starter list of the app's critical runtime capabilities
   from the codebase (an HTTP server → "boots + serves /health"; pdfkit →
   "renders a PDF"; ffmpeg calls → "transcodes media"; a migrate script → "runs
   DB migrations"; ssh2 → "parses/uses SSH keys"). Show the list, let the user
   edit it. Then, for each capability, create a **probe**: a small command or
   script that drives that capability against the *built image* and asserts
   success. Save probes under the workspace so every risky stage reuses them.
   See `references/capability-probes.md` for how to infer capabilities and the
   probe catalog.

4. **Set up the branch.** Do the work on a dedicated branch so each stage can be
   its own commit and escaping is clean.

Present the plan: baseline size, the stages that apply (with the skipped ones and
why), and the capability probes. Then start the loop.

## Step 2 — The per-stage gate loop

For each applicable stage, in order:

1. **Preview.** State what this stage changes, the detection-adapted specifics for
   this project, its risk, and a rough expected impact. (Read the stage's
   reference doc now.)
2. **Apply** the change(s).
3. **Build + measure** with `measure-image.sh`, passing the previous stage's size
   as `--baseline-bytes` so the report shows this stage's delta and the cumulative
   delta, plus which layers moved.
4. **Verify** at the depth the stage calls for:
   - low-risk stages (1-3): build succeeds + boot smoke (container starts and
     fails only on expected missing env, not a missing module or crash) + the
     project's own `type-check`/tests if quick.
   - risky stages (4-7): run **every capability probe** against the freshly built
     image and record pass/fail.
5. **Report card.** A tight summary: size before→after, this-stage Δ and
   cumulative Δ, risk level, per-probe pass/fail, and any caveat (e.g. "the S3
   round-trip is integration-level - verify on staging").
6. **Gate.** If verification passed, commit the stage (message includes the size Δ
   and a one-line verification summary), then ask the user: **continue to the next
   stage / stop here (escape) / skip the next stage but continue / show details.**
   If verification failed, go to failure handling.

## Failure handling

The point of verifying is to catch the breakage that only shows up in the image.
When it happens:

- **Build fails** → revert this stage's changes, show the error, and offer:
  try a fix / skip this stage / finish here.
- **A probe fails** → diagnose from the actual error. The classic case: a runtime
  "cannot find module X" after Stage 7 means X is read at runtime but wasn't in
  the prune roots (this is exactly how an unbundled migrator loses `postgres`).
  Fix by adding the root and rebuilding, then re-verify. Cap auto-fix attempts
  (default 2); if it still fails, revert the stage, keep every earlier stage's
  wins, and report what's blocking so the user can decide.

Because each stage is an isolated commit, a failed stage never costs you the
stages before it.

## Step 3 — Escape / finish

Whenever the user escapes (or the ladder is exhausted):

- Summarize cumulative savings (baseline → final, %), and list the per-stage
  commits so a reviewer can drop any single one.
- Collect every deferred caveat in one place: integration-level changes that need
  a **staging smoke-test** (storage, DB), and any **supply-chain** notes (Stage 4
  static binaries pinned by digest lose the distro's security cadence).
- Hand off per the project's convention (open a PR, or leave the branch). Do not
  deploy.

## Cross-cutting principles (hold on every stage)

- **Detect-then-adapt.** Re-check detection at each stage and pick the matching
  technique or skip. The same stage looks different on Bun vs Node vs Deno, or
  with esbuild vs bun build. A later stage can also *invalidate* an earlier one's
  choice - a base swap changes the whole package catalog, so a tool workaround
  that was lean on the old base may be heavy on the new one. Revisit earlier tool
  decisions after a base swap rather than carrying them forward on inertia
  (Stage 5 spells this out).
- **Explain the trade, don't just make it.** The user is choosing intensity; each
  report card should make the size/risk trade legible enough to decide on.
- **If you can't test it, flag it - don't sneak it.** Prefer a verified smaller
  win the user trusts over an unverified bigger one they don't.
