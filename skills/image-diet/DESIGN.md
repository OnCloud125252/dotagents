# Design: `image-diet` — progressive JS container-image slimmer (global skill)

- Date: 2026-07-20
- Status: design approved, pending written-spec review
- Origin: generalized from a real session that took a Bun/Elysia API image from
  1.28GB -> 369MB (-71%) plus two worker images 204MB -> 111MB.

## 1. Goal

A **global** Claude Code skill (lives in `~/.claude/skills/`, applies to any JS
project) that slims a project's container image through a **progressive pipeline**
of optimization stages ordered small/safe -> large/code-changing. The user picks
the optimization *intensity* by deciding where to **escape** the pipeline after
seeing each stage's real, measured result.

## 2. Scope & non-goals

In scope:

- Detect the project (runtime / package manager / bundler / base image / native
  deps) and adapt each stage accordingly ("detect-then-adapt").
- Apply, build, measure, and verify one stage at a time; gate on the user.
- Verify with adaptive depth: cheap stages get boot smoke; risky stages exercise
  user-declared "critical capabilities" via generated probes.

Non-goals (YAGNI):

- The skill never touches staging or production. Integration-level changes it
  can't fully verify locally are applied + flagged as "needs staging smoke-test",
  not driven against live infra.
- Not a one-shot automated CLI; stages that need judgment (which dep is dead,
  which lib to swap) are agent-reasoned, not hardcoded.

## 3. Key decisions

1. **Portability**: broadly JS, detect-then-adapt. Universal stages (build
   hygiene, dep diet, base swap, closure prune) run anywhere; runtime-specific
   moves (e.g. native S3 client) are gated behind detection.
2. **Interaction**: progressive gate. Each stage: apply -> build -> measure ->
   verify -> report card -> ask {continue / escape / skip-next / details}.
3. **Verification**: adaptive depth + declared capabilities. Safe stages ->
   build+boot smoke; risky stages -> run every capability probe.
4. **Skill structure**: `SKILL.md` controller + per-stage `references/` docs
   (progressive disclosure) + deterministic `scripts/`.

## 4. Tier ladder (small -> large)

Fixed order by ascending risk/effort. Detection **skips** inapplicable stages
(e.g. Stage 4 when there is no fat native tool, Stage 6 when there is no heavy
swappable lib) but never reorders — the ascending-risk walk is what makes the
"escape point = intensity" contract legible. Rightmost column = the session
result that validates the technique.

| Stage | Does | Touches | Risk | Verify | Session evidence |
|---|---|---|---|---|---|
| 1. Build hygiene | `.dockerignore`, multi-stage, prod-only install, apt/apk `--no-install-recommends` + clean, single RUN | Dockerfile | very low | build + boot smoke | part of 1.28G->826M |
| 2. Dependency diet | remove dead deps (0 imports), move dev tooling -> devDependencies, prune over-broad assets (fonts to loaded weights), drop build-only files from image (migration snapshots, sourcemaps, tests) | package.json + Dockerfile | low | build + type-check + tests | 1.28G->826M |
| 3. Bundle the app | bundle to a single file via the project's bundler (bun build / esbuild / tsup) so runtime needs little of node_modules | build pipeline | low-med | boot + capability smoke | enables Stage 7 |
| 4. Lean native tools | fat native tool -> prebuilt static binary (apt ffmpeg -> static ffmpeg) or lean lib (libvips-tools -> libheif); small caller-side code edit if needed | Dockerfile + small code | med | exercise that capability | ffmpeg -146M; vips->libheif -146M |
| 5. Base image swap | debian-slim -> alpine (musl), gated on no glibc-only deps (static binaries ok, native addons must degrade) | Dockerfile | med (gated) | exercise all capabilities on musl | api -83M; workers -93M each |
| 6. Runtime built-ins | replace heavy libs with runtime built-ins / lighter alts (aws-sdk -> Bun.S3Client / native fetch signer; moment -> Intl; lodash -> native) | runtime code | med-high | exercise swapped capability (often integration -> staging caveat) | aws-sdk -> Bun.S3Client -18M |
| 7. Runtime closure | grep the bundle for baked node_modules paths + dynamic require/resolve -> roots, add unbundled-entrypoint deps (e.g. migrator's postgres), keep roots + transitive closure, delete the rest of node_modules | Dockerfile + generated prune script | high | exercise ALL capabilities + every unbundled entrypoint | node_modules 95.8M->29.6M; 435M->369M |

### Cross-cutting principles (every stage obeys)

- **Detect-then-adapt**: each stage entry re-checks detection and picks the
  matching technique or skips.
- **One stage = one commit** on a dedicated branch. Escape = stop here. A stage
  that regresses size or fails verification = revert that commit; earlier stages
  stay. Reviewers can drop any single stage later.
- **If you can't test it, don't sneak it in**: image-only breakage (runtime-read
  data files, unbundled entrypoints) is invisible to unit tests, so high-risk
  stages must exercise the declared capability probes.

## 5. Pipeline mechanics

### Onboarding (once)

1. **Detect** via `scripts/detect-project.mjs` ->
   `{runtime, pkgManager, bundler, baseImage, dockerfiles[], nativeDeps[], glibcOnlyDeps[]}`.
   Multi-service: ask which Dockerfile to target.
2. **Baseline**: build current image, record size + `docker history` layer split.
3. **Declare capabilities + generate probes**: infer a default capability list
   from the codebase (pdfkit -> "PDF"; a migrate script -> "DB migrate"; an HTTP
   server -> "boot + /health"), user edits. For each capability, generate a
   **probe**: a small script/command that drives that capability against the
   *built image* and asserts success (e.g. render a PDF, transcode a clip, parse
   an SSH key, run the migrator). Probes are reused on every risky stage.

### Per-stage loop

```
preview (what changes, detected adaptation, risk, est. impact)
  -> apply
  -> build + measure (new size, delta, cumulative delta, layer diff)
  -> verify (adaptive: safe -> boot smoke; risky -> all capability probes)
  -> report card (size before->after, risk, per-probe pass/fail, caveats)
  -> gate:
       pass -> commit stage, ask {continue / escape / skip-next / details}
       fail -> failure handling
```

### Failure handling

- **build fails** -> revert stage -> show error -> {try-fix / skip-stage / finish}.
- **probe fails** (the migrator-missing-`postgres` case) -> diagnose (e.g.
  "runtime cannot find module X" -> Stage 7: add X to roots, rebuild, re-verify)
  -> bounded auto-fix (default 2 attempts) -> else revert stage, keep prior
  results, report.

### Escape / finish

Summarize cumulative savings, list per-stage commits, collect all "needs staging
smoke-test" caveats (integration-level changes) and supply-chain notes (pinned
third-party binaries), hand off per project convention (open PR / stay on branch).

## 6. File structure

```
~/.claude/skills/image-diet/
├── SKILL.md                      # controller: frontmatter(name + trigger phrases) + onboarding + gate loop + escape
├── references/
│   ├── detection.md              # how to detect runtime/pkgmgr/bundler/base/native+glibc deps; JSON shape
│   ├── capability-probes.md      # infer capabilities, generate/reuse probes, assert against a built image
│   ├── stage-1-build-hygiene.md
│   ├── stage-2-dependency-diet.md
│   ├── stage-3-bundle.md
│   ├── stage-4-lean-tools.md
│   ├── stage-5-base-swap.md
│   ├── stage-6-runtime-builtins.md
│   └── stage-7-runtime-closure.md
└── scripts/
    ├── detect-project.mjs        # emits detection JSON
    ├── measure-image.sh          # build + size + docker history layer diff vs baseline
    ├── bundle-roots.mjs          # grep a bundle for baked node_modules paths + dynamic require/resolve -> roots
    └── prune-runtime-modules.mjs # closure prune, ROOTS parameterized (generalized from this session)
```

### `stage-N-*.md` template (uniform so the controller handles them the same)

1. **When to run / skip** — detection predicate (e.g. Stage 5 only if `glibcOnlyDeps == []`).
2. **Adapt by detection** — runtime/pkgmgr/bundler branches (this is where detect-then-adapt lives).
3. **Apply** — concrete edits.
4. **Risk & expected impact.**
5. **Verify** — depth + which probes.
6. **Gotchas (portable)** — unbundled entrypoints need their deps kept; base swap
   gated on glibc-only deps; static binary must be truly static + match arch;
   packages that read their own data files at runtime (pdfkit AFM) must not be pruned.

### Scripts

- `.mjs` (runs on Node or Bun — supports detect-then-adapt); `measure-image.sh`
  is bash over the docker CLI.
- `prune-runtime-modules.mjs` and `bundle-roots.mjs` are the codified version of
  what this session did by hand.

## 7. Caveats / open items

- **Prune maintenance contract**: Stage 7's roots are derived from the current
  bundle; future dynamic requires / new data-file packages / new unbundled
  entrypoints must be re-derived. `bundle-roots.mjs` makes this repeatable.
- **Local-verification boundary**: Stage 6/7 changes to I/O-heavy paths (storage,
  DB) are integration-level; the skill verifies what it can locally and flags the
  rest for a human staging smoke-test.
- **Supply chain**: Stage 4 static binaries come from third-party images/releases;
  pin by digest, note the loss of distro security cadence.

## 8. Terminal step

Because this is a global skill (not a change to a specific repo), the normal
`/openspec-propose` handoff does not apply. After written-spec review, build the skill
files with the `skill-creator` skill.
