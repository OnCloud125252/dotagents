# Stage 3 — Bundle the app

Compile the app to a small self-contained bundle so the runtime image needs
little or none of `node_modules`. This is modest on its own but is the enabler for
Stage 7 (closure prune).

## When to run / skip

Run when a bundler is available/practical. **Skip** when the app can't be bundled
cleanly (heavy reflective/dynamic `require`, plugin systems that scan directories)

- note that Stage 7 then likely doesn't apply either.

## Adapt by detection

- **Bun**: `bun build src/index.ts --target bun --production --outdir dist`.
- **esbuild**: `esbuild src/index.ts --bundle --platform=node --target=node20 --outfile=dist/index.js` (mark truly-native/optional modules `--external`).
- **tsup / rollup / webpack / ncc**: use the project's configured bundler.
- **Deno**: often already single-file friendly (`deno compile` or a bundle step).
- Keep any **unbundled entrypoints** (e.g. a migrate script intentionally run
  directly) as-is, and remember they still need their own deps at runtime.

## Apply

- Bundle the main entrypoint to `dist/` and run the image from the bundle.
- Externalize what can't/shouldn't be bundled (native `.node`, optional deps) and
  note them - Stage 7 must keep those.
- Leave data files alone: bundlers inline code, not a package's runtime-read data
  files (fonts, `.afm`, `.trie`); those still resolve from `node_modules` at
  runtime.

## Risk & impact

Low-medium. The bundle itself is small; the payoff is unlocking Stage 7. The risk
is a dynamic require the bundler couldn't resolve - which surfaces at runtime.

## Verify

Boot smoke + every capability probe. A bundling gap shows up as a runtime
`Cannot find module` on the path that needed the un-inlined specifier - which is
why you exercise capabilities, not just startup.

## Gotchas (portable)

- After bundling, the app may still read files from `node_modules` at runtime via
  a **baked absolute path** (bundlers freeze `__dirname`/`import.meta.dir` at build
  time). Those packages must remain at the same path in the final image - this is
  the fact Stage 7 depends on.
- Don't assume `--target node` vs `--target bun` are interchangeable; pick the one
  matching the runtime so built-ins resolve correctly.
