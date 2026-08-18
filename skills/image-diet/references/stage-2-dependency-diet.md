# Stage 2 — Dependency diet

Trim what ships in `package.json` and the image, without touching runtime logic.

## When to run / skip

Almost always something here. Skip if a prior audit already removed dead deps and
there are no bulky assets.

## Adapt by detection

- Dead-dep and dev-vs-prod checks work the same across pkg managers; the
  production-install command differs (see Stage 1).
- Asset packages differ by ecosystem (fonts via `@fontsource/*`, icon sets, locale
  data, wasm blobs) - find the ones actually imported.

## Apply

- **Remove dead dependencies**: any package in `dependencies` with zero imports
  in the source (grep for the specifier; watch for dynamic/optional uses). These
  ship in the image and often in the bundle. Confirm truly-zero before removing.
- **Move dev-only tooling to `devDependencies`**: linters, formatters, test
  runners, typescript, type packages, bundlers. Anything only used at build/CI
  time must not be a production dependency, or a prod install still pulls it.
- **Prune over-broad assets**: ship only the slices you load - the font weights
  actually registered, the one locale, the used icons. A font/icon package can be
  tens of MB of variants you never reference.
- **Drop build-only files from the image**: sourcemaps you don't need in prod,
  test files, and generator-only artifacts (e.g. an ORM's migration *snapshot*
  JSON that only its `generate` command reads, not the runtime migrator).

## Risk & impact

Low - it's packaging, not behaviour. Impact is moderate and reliable.

## Verify

Build + type-check + the project's tests (fast ones) + boot smoke. If you pruned
an asset, run the probe that uses it (e.g. render a PDF after pruning fonts) to
confirm the kept slice is enough.

## Gotchas (portable)

- "Zero imports" must include dynamic `import()`, `require(var)`, and config-file
  references. A dependency can also be an *optional peer* pulled only on a code
  path you don't use - safe to leave uninstalled, but confirm.
- Pruning an asset package couples the image to that package's internal file
  layout; a version bump can move files. The failure is loud (ENOENT at first
  use) - a probe catches it.
- Removing a dep changes the lockfile; regenerate and re-run the build.
