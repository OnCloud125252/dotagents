#!/usr/bin/env node
// Prune node_modules to a runtime closure.
//
// A bundled app (dist bundle) needs almost none of node_modules at runtime -
// only the packages the bundle still reads from disk (data files behind a baked
// __dirname, dynamic require()/resolve() targets) plus any UNBUNDLED entrypoint's
// imports (e.g. a migrate script run as `node src/migrate.js`). Keep those roots
// and their full transitive dependency closure; delete everything else. Nested
// deps ride along with their parent because only top-level entries are removed.
//
// Runs on Node or Bun. Operates on ./node_modules relative to cwd.
//
// Usage:
//   node prune-runtime-modules.mjs pdfkit ioredis ssh2 ajv postgres
//   ROOTS="pdfkit,ioredis ssh2" node prune-runtime-modules.mjs
//   NODE_MODULES_DIR=/app/node_modules node prune-runtime-modules.mjs <roots...>

import { existsSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";

const NODE_MODULES = process.env.NODE_MODULES_DIR || "node_modules";

const argRoots = process.argv.slice(2);
const roots = (argRoots.length ? argRoots : (process.env.ROOTS || "").split(/[\s,]+/)).filter(Boolean);

if (roots.length === 0) {
  console.error("prune-runtime-modules: no roots given (argv or ROOTS env)");
  process.exit(1);
}
if (!existsSync(NODE_MODULES)) {
  console.error(`prune-runtime-modules: ${NODE_MODULES} not found`);
  process.exit(1);
}

const keep = new Set();

function visit(pkg) {
  if (keep.has(pkg)) {
    return;
  }
  const manifestPath = join(NODE_MODULES, pkg, "package.json");
  if (!existsSync(manifestPath)) {
    // Not hoisted to the top level: it is nested under a parent and will be
    // kept transitively when the parent dir is kept.
    return;
  }
  keep.add(pkg);
  let manifest;
  try {
    manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  } catch {
    return;
  }
  const deps = {
    ...(manifest.dependencies ?? {}),
    // optionalDependencies may be require()d behind a try/catch at runtime.
    ...(manifest.optionalDependencies ?? {}),
  };
  for (const dep of Object.keys(deps)) {
    visit(dep);
  }
}

for (const root of roots) {
  visit(root);
}

function topLevelEntries() {
  const entries = [];
  for (const name of readdirSync(NODE_MODULES)) {
    if (name === ".bin" || name === ".cache") {
      continue;
    }
    if (name.startsWith("@")) {
      for (const scoped of readdirSync(join(NODE_MODULES, name))) {
        entries.push(`${name}/${scoped}`);
      }
    } else {
      entries.push(name);
    }
  }
  return entries;
}

let removed = 0;
for (const entry of topLevelEntries()) {
  if (!keep.has(entry)) {
    rmSync(join(NODE_MODULES, entry), { recursive: true, force: true });
    removed += 1;
  }
}

// Remove now-empty scope dirs left behind after their only package was pruned.
for (const name of readdirSync(NODE_MODULES)) {
  if (name.startsWith("@") && readdirSync(join(NODE_MODULES, name)).length === 0) {
    rmSync(join(NODE_MODULES, name), { recursive: true, force: true });
  }
}

console.info(`prune-runtime-modules: kept ${keep.size}, removed ${removed}`);
