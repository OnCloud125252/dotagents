# Stage 6 — Runtime built-ins & lighter alternatives

Replace a heavy library with a runtime built-in or a much smaller alternative.
This is a real code change, so it earns its place only when the lib is genuinely
heavy and the replacement is well-understood.

## When to run / skip

Run when a bulky dependency has a faithful lighter/built-in replacement for the
narrow way the app uses it. Skip if the lib is used deeply or the replacement
would be a risky rewrite.

## Adapt by detection — prefer the runtime's own batteries

- **Bun**: `Bun.S3Client` (S3/R2/compatible), `Bun.file`/`Bun.write`, built-in
  SQLite, `Bun.password`, `fetch` - remove `@aws-sdk/*`, `better-sqlite3`, `bcrypt`,
  `axios` where the usage is basic.
- **Node**: `fetch`/`undici` (drop `axios`/`node-fetch`), `node:crypto`,
  `node:sqlite` (newer Node), `Intl` (drop `moment`/`dayjs` for formatting),
  native array/object methods (drop most `lodash` uses), `structuredClone`.
- **Deno**: web platform APIs + std.
- Common heavy→light swaps that aren't runtime-specific: `moment` → `date-fns`/
  `Intl`, full `lodash` → `lodash.<fn>`/native, a full AWS SDK → a tiny S3 signer
  (`aws4fetch`) when no built-in exists.

## Apply

- Replace the import and rewrite the (usually few) call sites to the new API,
  preserving the existing function's contract exactly (same inputs/outputs, same
  null/streaming/error behaviour).
- Remove the old dependency from `package.json`; regenerate the lockfile. This
  shrinks both the bundle and node_modules.

## Risk & impact

Medium-high - it's runtime behaviour. Impact varies (a fat SDK can be tens of MB
across bundle + node_modules).

## Verify

Run the probe for the swapped capability. Many of these (storage, DB) are
**integration-level** - you can unit-test the pure logic and construction, but the
real round-trip needs credentials/services. Verify what you can locally and flag
the rest for a **staging smoke-test** in the caveats; don't call it done on
type-check alone.

## Gotchas (portable)

- Preserve subtle contract details: a download that returned `null` on 404, a
  stream vs a buffer, content-type/length headers, path-style vs virtual-host S3
  addressing (custom endpoints like R2/MinIO/Garage usually need path-style).
- Built-in clients evolve; confirm the API exists in the project's pinned runtime
  version, not just the latest docs.
- Don't over-reach: swapping a library the app leans on heavily for a 2 MB win is
  a bad trade. This stage is opt-in per dependency.
