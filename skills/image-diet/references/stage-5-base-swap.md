# Stage 5 — Base image swap

Move to a smaller base (debian-slim → alpine/musl, or → distroless). The base is
often the biggest fixed cost once the app itself is lean.

## When to run / skip

Gate: run only when there are **no glibc-only native dependencies** left that the
app relies on. Stages 4 and 6 often *create* this opportunity by removing the
glibc-heavy pieces. If `glibcRiskDeps` is non-empty, resolve or verify each before
attempting alpine.

## Adapt by detection

- **runtime image**: swap to the alpine variant of the same runtime
  (`node:*-alpine`, `oven/bun:*-alpine`, etc.).
- **package system flips** with the base: `apt-get ...` → `apk add --no-cache ...`.
  Re-express any Stage 1/4 installs in the new manager (package names may differ,
  and are often smaller on alpine).
- **distroless** is even smaller/safer but has no shell/package manager - only fits
  a fully self-contained bundle + static binaries, and breaks shell-form
  HEALTHCHECKs.

## Apply

- Change the final stage's `FROM` to the musl base.
- Re-install system packages via the new manager.
- Keep the build stage on the fuller base if that's simpler - it doesn't affect
  final size.
- **Re-evaluate every Stage 1/4 tool decision on the new base - this is the step
  most easily missed.** A Stage 4 workaround (a static binary, a lean-lib swap, or
  the code change either required) was chosen to escape the *old* base's package
  quality. The new base has a different catalog, and a tool that was bloated there
  is often lean here - which can make the workaround both unnecessary *and heavier*.
  When that's the case, revert to the new base's native package and drop the
  workaround (including any code change it forced). Concretely: Debian's apt
  `ffmpeg` pulls a ~350 MB GPU/LLVM graph, so Stage 4 might swap in a ~200 MB
  static build; but Alpine's apk `ffmpeg` is only tens of MB (musl, shared libs,
  no GPU stack), so on Alpine the static binary is *larger* than just
  `apk add ffmpeg` - and dropping it also sheds a third-party supply-chain pin.
  Likewise a fat Debian `libvips-tools` (~150 MB) might justify swapping HEIC
  decode to a leaner lib with a code edit, whereas Alpine's modular vips
  (`vips-tools` + `vips-heif`) is small enough to keep as-is, so the code change
  is not worth carrying. **Measure both options on the new base before deciding** -
  don't assume the earlier decision still holds.

## Risk & impact

Medium, but gated. Impact is a large, fixed reduction (musl bases are roughly half
a slim Debian base).

## Verify

This is a libc change, so **run every capability probe on musl**, not just boot.
Especially exercise anything doing crypto, native addons, DNS, or spawning tools.
Confirm the base still provides what you rely on: CA certificates for outbound
HTTPS, and a shell if a HEALTHCHECK needs one. For timezones, don't reflexively
`apk add tzdata` - a runtime with bundled ICU (Bun, or Node built with full-icu)
resolves IANA zones like `Asia/Taipei` through `Intl` (and often `TZ`) without
system zoneinfo. Probe an actual non-UTC format first and add `tzdata` only if it
fails; otherwise it's dead weight.

## Gotchas (portable)

- A native addon built against glibc won't load on musl. If it's **optional** and
  the library degrades gracefully (falls back to JS), you're fine - prove it with
  a probe. If it's load-bearing, don't swap (or find a musl build).
- musl DNS and some libc corners differ from glibc; runtimes that use their own
  resolver (e.g. Bun) sidestep this, but verify networked capabilities.
- Static binaries from Stage 4 must still run here - they do if truly static, but
  check. And per the re-evaluation step above, a static binary that was the lean
  choice on the old base may be the *heavy* choice on this one - don't keep it out
  of inertia.
