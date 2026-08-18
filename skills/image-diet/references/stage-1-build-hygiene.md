# Stage 1 — Build hygiene

Free, behaviour-neutral wins from how the image is built.

## When to run / skip

Always applicable. Skip individual items already present (e.g. a good
`.dockerignore`, an existing multi-stage build).

## Adapt by detection

- **prod install** by pkgManager: `bun install --production --frozen-lockfile` /
  `npm ci --omit=dev` / `pnpm install --prod --frozen-lockfile` /
  `yarn install --production --frozen-lockfile`.
- **package system** by base: Debian/Ubuntu → `apt-get`; Alpine → `apk`.
- No Dockerfile yet → author a minimal multi-stage one (build stage installs +
  builds; runtime stage copies only what runs).

## Apply

- **`.dockerignore`**: exclude `node_modules`, `.git`, tests, docs, CI, local env
  files, build caches. This shrinks the build *context* (faster, avoids leaking
  secrets); it also prevents `COPY . .` from dragging junk into the image.
- **Multi-stage**: build/compile in one stage, copy only runtime artifacts into a
  clean final stage so build tools and dev deps never ship.
- **Production-only install** in the runtime deps stage (devDependencies excluded).
- **apt/apk footprint**: `apt-get install -y --no-install-recommends ... && apt-get clean && rm -rf /var/lib/apt/lists/*` in a single `RUN` (Alpine: `apk add --no-cache ...`). "Recommends" on Debian can pull hundreds of MB the app never uses.

## Risk & impact

Very low; no runtime code changes. Impact ranges from small to large - the apt
`--no-install-recommends` alone can be huge if the image installs heavy tools.

## Verify

Build succeeds + boot smoke. If the image installs a tool (ffmpeg, imagemagick),
run that tool's probe to confirm `--no-install-recommends` didn't drop a codec you
use.

## Gotchas (portable)

- `.dockerignore` only affects the build context and `COPY` - it does **not**
  shrink layers copied from another stage.
- Pinning apt/apk versions is often *more* fragile than not (rolling repos drop
  old versions), so unpinned is a defensible default; call it out either way.
- Keep the heavy, rarely-changing `RUN` (system packages) early so it stays cache
  -hit across code changes.
