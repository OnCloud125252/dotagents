# Capability probes

Probes are the reason this pipeline can be aggressive safely. A probe is a small,
reusable check that drives one real capability of the app **against the built
image** and asserts it worked. The scary stages (4-7) rerun every probe, so a
change that quietly breaks a runtime-only path (a data file the bundle reads, an
unbundled entrypoint's dependency) is caught before the user is asked to continue.

## Why "against the built image", not the source tree

Most breakage from these optimizations does not reproduce in `node_modules` on
your dev machine or in unit tests - it only appears once code is bundled and
node_modules is pruned inside the image. So probes must run in a container built
from the candidate Dockerfile, e.g.:

```bash
# boot smoke: starts, and fails only on missing env (not a missing module/crash)
docker run --rm <tag> 2>&1 | head -20

# drive a capability by mounting a probe script and running it in the image
docker run --rm -v "$PROBE":/probe.mjs --entrypoint <runtime> <tag> /probe.mjs

# drive a CLI/tool capability directly
docker run --rm --entrypoint <tool> <tag> <args...>
```

## Inferring the starter capability list

Read the codebase and propose capabilities from concrete signals, then let the
user correct it:

| Signal in the project | Candidate capability |
|---|---|
| an HTTP server / framework, a health route | boots and serves `/health` (or the real health path) |
| `pdfkit` / `@react-pdf` / puppeteer | renders a document/PDF |
| shells out to `ffmpeg`/`ffprobe`/`sharp`/`vips`/`heif-*` | processes media (transcode/thumbnail) |
| a migrate script / drizzle / prisma / knex | runs DB migrations (often an UNBUNDLED entrypoint) |
| `ssh2` / `node-forge` / crypto signing | parses a key / signs |
| an S3/object-storage client | uploads/downloads/deletes an object |
| a background worker entrypoint | boots the worker loop |

Prefer 3-6 probes that cover the app's load-bearing paths and the paths these
optimizations most endanger (anything that reads files at runtime, any separate
entrypoint).

## Probe design rules

- **Assert, don't eyeball.** A probe exits non-zero on failure and prints a clear
  pass line (e.g. `PDF_OK bytes=9245`), so the gate can read it mechanically.
- **Self-contained + deterministic.** Generate fixtures in-container (ffmpeg
  `lavfi` test source, a generated key, a tiny sample file) instead of depending
  on network or secrets.
- **Distinguish "expected env failure" from "broken".** A boot probe should treat
  "DATABASE_URL is required" as success (the module graph loaded); a
  `Cannot find module` / segfault / `MODULE_NOT_FOUND` is failure.
- **Cover every entrypoint.** If the image ships more than the main process (a
  migrate initContainer, a worker), each gets a boot probe - the migrator running
  unbundled is the single most common thing a Stage 7 prune breaks.
- **Reuse across stages.** Save probes in the workspace once; every risky stage
  runs the same set, so results are comparable stage to stage.

## Example probes

**Boot smoke (any server):**

```bash
out=$(docker run --rm <tag> 2>&1 | head -30)
echo "$out" | grep -qiE 'cannot find module|MODULE_NOT_FOUND|segmentation' && { echo "BOOT_FAIL"; exit 1; }
echo "BOOT_OK"
```

**PDF render (pdfkit), run inside the image:**

```js
// probe-pdf.mjs
const PDFDocument = require("pdfkit");
const doc = new PDFDocument();
const chunks = [];
doc.on("data", (c) => chunks.push(c));
doc.on("end", () => {
  const b = Buffer.concat(chunks);
  const ok = b.slice(0, 5).toString() === "%PDF-" && b.length > 1000;
  console.log(ok ? `PDF_OK bytes=${b.length}` : "PDF_FAIL");
  process.exit(ok ? 0 : 1);
});
doc.text("probe 測試").end();
```

**Media (ffmpeg), direct:**

```bash
docker run --rm --entrypoint ffmpeg <tag> -y -loglevel error \
  -f lavfi -i testsrc=duration=1:size=64x64:rate=5 -c:v libx264 /tmp/o.mp4 \
  && echo "FFMPEG_OK"
```

**Unbundled migrator (resolves its deps, reaches its env check):**

```bash
docker run --rm --entrypoint <runtime> <tag> src/db/migrate.js 2>&1 | tail -1
# pass = its own "DATABASE_URL required"-style message; fail = cannot find module
```

Adapt the exact commands to the runtime (`bun` vs `node`) and the project's real
entrypoints and capabilities.
