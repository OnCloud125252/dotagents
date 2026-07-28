# Stage 4 — Lean native tools

Replace a fat system package with a lean equivalent that does the same job. Often
the single biggest win when the image installs heavy media/imaging tooling.

## When to run / skip

Run only if the image installs a heavy native tool (ffmpeg, imagemagick, libvips,
chromium, poppler, texlive...). Skip if there's no such tool.

## Adapt by detection

- Identify what the app actually calls (grep for the tool's binary name / the
  lib's API) and which *features* it needs - you're replacing capability, not the
  whole package.
- Static-binary sources differ by tool; prefer a maintained, digest-pinnable image
  or release.

## Apply — two common shapes

- **Fat apt tree → prebuilt static binary.** A distro's `ffmpeg` can hard-depend
  on a large GPU/LLVM/codec graph a headless server never uses. A static build is
  a couple of self-contained binaries. Copy them from a **digest-pinned** image:

  ```dockerfile
  FROM someorg/static-ffmpeg:<ver>@sha256:<digest> AS ffmpeg
  ...
  COPY --from=ffmpeg /ffmpeg /ffprobe /usr/local/bin/
  ```

  A multi-arch pinned image resolves the right arch automatically (no per-arch
  curl/checksum logic), and the digest is a builder-verified checksum.
- **Fat lib → lean lib (may need a small code edit).** e.g. a full imaging suite
  installed only to decode one format → a single-purpose decoder, then reuse a
  tool you already have for the rest (decode with the lean lib, resize with the
  ffmpeg you kept). Update the few call sites.

## Risk & impact

Medium; can touch a few lines of code. Impact is often large.

## Verify

Run the media/tool probe(s) for the real operations (e.g. the exact transcode
args, the exact decode+resize). Confirm the specific codecs/formats you use are
present in the replacement - a leaner build may omit an encoder you need.

## Gotchas (portable)

- A "static" binary must be *truly* static (runs on any libc) and match the target
  arch - verify by running it in the final base, not just the source image.
- When swapping a decode/resize lib, keep the *same underlying library* where
  correctness matters (e.g. decode HEIC with the same libheif the fat tool used)
  so output quality/edge-cases don't regress.
- Third-party binaries trade the distro's security cadence for a pin - record the
  pin and that trade in the caveats.
- **This choice is base-dependent.** A static binary / lean-lib swap justified by
  the *current* base's bloated package may be unnecessary (and heavier) on a
  smaller base. If Stage 5 (base swap) is on the table, expect to revisit this
  decision there and possibly revert to the new base's native package - see
  `stage-5-base-swap.md`. Don't over-invest in a workaround (especially a code
  change) that a later base swap will make redundant.
