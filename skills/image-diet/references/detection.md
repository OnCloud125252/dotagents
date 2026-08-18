# Detection

The pipeline adapts to the project instead of assuming one stack. Run
`scripts/detect-project.mjs` from the project root; it prints JSON:

```json
{
  "runtime": "bun | node | deno",
  "pkgManager": "bun | pnpm | yarn | npm | unknown",
  "bundler": "none | bun | esbuild | tsup | webpack | rollup | vite | ...",
  "dockerfiles": ["Dockerfile", "dockerfiles/Dockerfile.api"],
  "baseImages": ["oven/bun:1.3.9-slim", "node:22-slim"],
  "nativeDeps": ["ssh2", "better-sqlite3"],
  "glibcRiskDeps": ["better-sqlite3"],
  "notes": ["..."]
}
```

## How each field steers the pipeline

- **runtime** - decides the built-in替代 available at Stage 6 (Bun: `Bun.S3Client`,
  `Bun.file`, built-in SQLite/password hashing; Node: `node:` built-ins, `fetch`,
  `node:sqlite` on new versions; Deno: std + web APIs) and the bundler default at
  Stage 3.
- **pkgManager** - the production-install incantation at Stage 1/2
  (`bun install --production`, `npm ci --omit=dev`, `pnpm install --prod`,
  `yarn install --production`) and how "dead dependency" is checked.
- **bundler** - whether Stage 3 (bundle) and therefore Stage 7 (closure prune)
  apply as written. `none` with no easy path to bundling → Stage 7 is usually off
  the table; say so.
- **dockerfiles / baseImages** - the target(s) to slim and the current base (is
  it already slim/alpine/distroless?).
- **nativeDeps / glibcRiskDeps** - the Stage 5 gate. A native addon that ships
  only a glibc prebuild blocks an alpine (musl) base unless it's optional and the
  app degrades without it. Treat this list as *suspects to verify*, not a verdict.

## Confidence and fallbacks

Treat `bundler` and `glibcRiskDeps` as **hints**, not truth:

- The script infers bundler from deps/scripts; a project may bundle via a config
  file it can't see. Confirm by looking at the build script.
- `glibcRiskDeps` flags anything that looks native (`gypfile`, `binding.gyp`,
  `node-gyp-build`/`prebuild`/`nan`). Some of these ship musl prebuilds (fine on
  alpine) or are optional (ssh2's `cpu-features`); others are hard blockers
  (`better-sqlite3` without a musl build). The real test is Stage 5's build +
  capability probes on musl - detection just tells you where to look.

If `node_modules` isn't installed, native scanning is empty and unreliable - note
it and install first.

## Multi-service repos

A repo may have several Dockerfiles sharing one `package.json`. Slim one image at
a time. Note that a `package.json` change (Stage 2/6) affects *every* service that
installs from it - a nice side benefit, but re-verify the others' baselines if
they matter.
