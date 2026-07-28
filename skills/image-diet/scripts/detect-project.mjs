#!/usr/bin/env node
// Best-effort project detection for the image-diet pipeline. Emits JSON:
//   { runtime, pkgManager, bundler, dockerfiles, baseImages, nativeDeps,
//     glibcRiskDeps, notes }
//
// This is a heuristic starting point, not an oracle. The skill should treat low
// -confidence fields (bundler, glibcRiskDeps) as hints to confirm, not truth.
// Runs on Node or Bun.

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const cwd = process.cwd();
const has = (f) => existsSync(join(cwd, f));
const read = (f) => {
  try {
    return readFileSync(join(cwd, f), "utf8");
  } catch {
    return "";
  }
};
const pkg = (() => {
  try {
    return JSON.parse(read("package.json") || "{}");
  } catch {
    return {};
  }
})();
const allDeps = { ...(pkg.dependencies ?? {}), ...(pkg.devDependencies ?? {}) };

// ── package manager ──────────────────────────────────────────────────────────
let pkgManager = "unknown";
if (has("bun.lock") || has("bun.lockb")) {
  pkgManager = "bun";
} else if (has("pnpm-lock.yaml")) {
  pkgManager = "pnpm";
} else if (has("yarn.lock")) {
  pkgManager = "yarn";
} else if (has("package-lock.json")) {
  pkgManager = "npm";
}

// ── runtime ──────────────────────────────────────────────────────────────────
let runtime = "node";
if (pkgManager === "bun" || pkg.engines?.bun || allDeps["@types/bun"] || has("bunfig.toml")) {
  runtime = "bun";
} else if (has("deno.json") || has("deno.jsonc") || has("deno.lock")) {
  runtime = "deno";
}

// ── bundler (hint) ───────────────────────────────────────────────────────────
const bundlerDeps = ["esbuild", "tsup", "webpack", "rollup", "vite", "@vercel/ncc", "parcel"];
let bundler = "none";
if (runtime === "bun") {
  bundler = "bun"; // `bun build` is always available
}
for (const b of bundlerDeps) {
  if (allDeps[b]) {
    bundler = bundler === "none" ? b : `${bundler}+${b}`;
  }
}
const scriptsText = JSON.stringify(pkg.scripts ?? {});
if (/\besbuild\b/.test(scriptsText) && !bundler.includes("esbuild")) {
  bundler = bundler === "none" ? "esbuild" : `${bundler}+esbuild`;
}

// ── dockerfiles + base images ────────────────────────────────────────────────
function findDockerfiles(dir, depth = 0, acc = []) {
  if (depth > 3) {
    return acc;
  }
  let names;
  try {
    names = readdirSync(dir);
  } catch {
    return acc;
  }
  for (const name of names) {
    if (name === "node_modules" || name === ".git" || name.startsWith(".")) {
      continue;
    }
    const full = join(dir, name);
    let s;
    try {
      s = statSync(full);
    } catch {
      continue;
    }
    if (s.isDirectory()) {
      findDockerfiles(full, depth + 1, acc);
    } else if (/^Dockerfile/i.test(name) || /\.Dockerfile$/i.test(name) || /^Dockerfile\./i.test(name)) {
      acc.push(full.replace(`${cwd}/`, ""));
    }
  }
  return acc;
}
const dockerfiles = findDockerfiles(cwd);
const baseImages = [];
for (const df of dockerfiles) {
  for (const m of read(df).matchAll(/^\s*FROM\s+([^\s]+)/gim)) {
    baseImages.push(m[1]);
  }
}

// ── native deps + glibc risk (heuristic) ─────────────────────────────────────
const nativeDeps = [];
const glibcRiskDeps = [];
const nmDir = join(cwd, "node_modules");
if (existsSync(nmDir)) {
  const scan = (rel) => {
    const p = join(nmDir, rel);
    if (!existsSync(join(p, "package.json"))) {
      return;
    }
    let m;
    try {
      m = JSON.parse(readFileSync(join(p, "package.json"), "utf8"));
    } catch {
      return;
    }
    const isNative =
      m.gypfile === true ||
      existsSync(join(p, "binding.gyp")) ||
      (m.dependencies && (m.dependencies["node-gyp-build"] || m.dependencies.prebuild || m.dependencies.nan));
    if (isNative) {
      nativeDeps.push(rel);
      // Native addons ship prebuilt .node binaries usually built against glibc;
      // they are the main blocker for an alpine (musl) base unless they are
      // optional or ship a musl prebuild. Flag for the skill to verify.
      glibcRiskDeps.push(rel);
    }
  };
  for (const name of readdirSync(nmDir)) {
    if (name.startsWith(".")) {
      continue;
    }
    if (name.startsWith("@")) {
      for (const scoped of readdirSync(join(nmDir, name))) {
        scan(`${name}/${scoped}`);
      }
    } else {
      scan(name);
    }
  }
}

const notes = [];
if (!existsSync(nmDir)) {
  notes.push("node_modules not installed - nativeDeps/glibcRiskDeps could not be scanned; run install first");
}
if (dockerfiles.length === 0) {
  notes.push("no Dockerfile found - Stage 1 may need to author one");
}
if (bundler === "none") {
  notes.push("no bundler detected - Stage 3 (bundle) and Stage 7 (closure prune) may not apply as-is");
}

console.log(
  JSON.stringify(
    { runtime, pkgManager, bundler, dockerfiles, baseImages, nativeDeps, glibcRiskDeps, notes },
    null,
    2,
  ),
);
