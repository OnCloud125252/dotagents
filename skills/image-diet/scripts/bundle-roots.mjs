#!/usr/bin/env node
// Derive the runtime node_modules roots a bundle still needs.
//
// A modern bundler inlines almost everything, but two kinds of reference still
// reach node_modules at runtime and MUST survive a prune:
//   1. A package that reads its own data files via a build-time-baked __dirname
//      (e.g. pdfkit's *.afm) - shows up as a literal `node_modules/<pkg>/...`
//      path in the bundle text.
//   2. A specifier the bundler could not statically inline - a bare
//      require("x") / import("x") / <createRequire>.resolve("x").
//
// This prints both, so you can feed the roots to prune-runtime-modules.mjs.
// It does NOT know about UNBUNDLED entrypoints (a migrate script run directly):
// add those packages' imports to the roots by hand.
//
// Usage: node bundle-roots.mjs dist/bundle.js

import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("usage: bundle-roots.mjs <bundle.js>");
  process.exit(1);
}

const src = readFileSync(file, "utf8");
const roots = new Set();
const dynamicSpecifiers = new Set();

// 1. Baked absolute paths: .../node_modules/<pkg> or .../node_modules/@scope/pkg
for (const match of src.matchAll(/node_modules\/(@[\w.-]+\/[\w.-]+|[\w.-]+)/g)) {
  roots.add(match[1]);
}

// 2. Dynamic bare specifiers (non-relative, non-builtin).
const specRegexes = [
  /\brequire\(\s*["'`]([^"'`.][^"'`]*)["'`]\s*\)/g,
  /\bimport\(\s*["'`]([^"'`.][^"'`]*)["'`]\s*\)/g,
  /\.resolve\(\s*["'`]([^"'`.][^"'`]*)["'`]\s*\)/g,
];
function topLevelPackage(spec) {
  if (spec.startsWith("@")) {
    const [scope, name] = spec.split("/");
    return `${scope}/${name}`;
  }
  return spec.split("/")[0];
}
// npm package names are lowercase; this rejects false positives like a
// `Promise.resolve("OK")` that the broad `.resolve("...")` pattern also matches.
const VALID_PKG = /^(@[a-z0-9-._~]+\/)?[a-z0-9-._~]+$/;
for (const regex of specRegexes) {
  for (const match of src.matchAll(regex)) {
    const spec = match[1];
    if (spec.startsWith("node:")) {
      continue;
    }
    const pkg = topLevelPackage(spec);
    if (!VALID_PKG.test(pkg)) {
      continue;
    }
    dynamicSpecifiers.add(spec);
    roots.add(pkg);
  }
}

const result = {
  roots: [...roots].filter((r) => !r.startsWith("node:") && VALID_PKG.test(r)).sort(),
  dynamicSpecifiers: [...dynamicSpecifiers].sort(),
};
console.log(JSON.stringify(result, null, 2));
