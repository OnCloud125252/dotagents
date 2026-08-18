# Stage 7 — Ship only the runtime node_modules closure

The most aggressive stage. Since the app runs from a bundle, ship only the handful
of packages the runtime actually reads from disk, plus their dependency closure -
delete the rest of `node_modules`.

## When to run / skip

Requires Stage 3 (a bundle). Skip if the app isn't bundled, or if it does heavy
reflective loading of arbitrary packages at runtime (a plugin host) that can't be
enumerated.

## Adapt by detection

- Works for any bundler that inlines code (bun build, esbuild, ...). The bundle is
  the source of truth for what's still referenced.
- The prune runs in the deps stage after a production install; `.mjs` runs on Node
  or Bun.

## Apply

1. **Derive the roots** with `scripts/bundle-roots.mjs <bundle>`. It reports:
   - packages whose files are read via a baked `node_modules/<pkg>/...` path
     (e.g. a PDF lib's font metrics), and
   - dynamic `require()`/`import()`/`.resolve()` specifiers the bundler couldn't
     inline (e.g. a validator's runtime helpers, an optional native module).
2. **Add unbundled-entrypoint deps by hand.** `bundle-roots.mjs` only sees the
   bundle. Any entrypoint shipped *unbundled* (classically a migrate script run as
   `node src/migrate.js`) needs its own imports kept - read that file and add its
   packages (e.g. the DB driver) to the roots.
3. **Prune**: `scripts/prune-runtime-modules.mjs <roots...>` keeps the roots + full
   transitive dependency closure and deletes every other top-level entry. Wire it
   into the Dockerfile's deps stage (after install + any asset prune):

   ```dockerfile
   COPY scripts/prune-runtime-modules.mjs .
   RUN <runtime> prune-runtime-modules.mjs pdfkit ioredis ssh2 ajv postgres ...
   ```

## Risk & impact

High. Impact is large (node_modules can drop by 60-90% of what remained). The risk
is a runtime path that needs a package you didn't list - invisible until that path
runs.

## Verify

Run **every** capability probe **and** a boot probe for **every** entrypoint,
including the migrator/worker. This is exactly where the pipeline earns its
verification discipline: the canonical failure is an unbundled migrator missing
its DB driver, or a glyph/format path needing a data-file package you pruned.

## Failure → fix loop

A probe failing with `Cannot find module X` (or a runtime file-not-found under
`node_modules/X`) means X is a missing root. Add X to the roots, rebuild, re-run
probes. Cap attempts; if it keeps surfacing new modules, the app may be too
dynamic for this stage - revert and keep Stage 1-6.

## Gotchas (portable)

- **Keep the whole package that owns a runtime-read data file**, not just the
  file - and its deps (a font parser reads its unicode-trie deps' data).
- **Conservative closure beats a minimal guess**: keeping a bundled-but-declared
  dep costs a few MB; missing one crashes production on some inputs.
- **This is a maintenance contract.** A future dynamic require, a new data-file
  package, or a new unbundled entrypoint must be re-derived. Re-run
  `bundle-roots.mjs` after changes that touch runtime loading, and keep the roots
  list documented next to the prune step.
