#!/usr/bin/env bash
#
# detect.sh — Stack detection for setup-hooks.
# Prints one line: "<stack>\t<reason>"
# Exit code 0 always; "unknown" indicates manual selection needed.
#
# Stacks (must match a directory under templates/):
#   go          — Go module repo
#   bun-biome   — bun package manager + biome formatter
#   pnpm-biome  — pnpm package manager + biome formatter
#   unknown     — caller should prompt the user
#
# Detection order is deliberate: Go wins over JS if both signals exist
# (rare but possible in polyglot repos).

set -u

REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$REPO" 2>/dev/null || { echo "unknown"$'\t'"cwd not accessible"; exit 0; }

emit() { printf '%s\t%s\n' "$1" "$2"; exit 0; }

# 1. Go
if [[ -f "go.mod" ]]; then
  emit "go" "go.mod present"
fi

# 2. JS — must have package.json
if [[ ! -f "package.json" ]]; then
  emit "unknown" "no go.mod and no package.json"
fi

# Determine package manager
pm=""
if command -v jq >/dev/null 2>&1; then
  pm_field=$(jq -r '.packageManager // empty' package.json 2>/dev/null)
  case "$pm_field" in
    bun@*)  pm="bun" ;;
    pnpm@*) pm="pnpm" ;;
    npm@*|yarn@*) pm="${pm_field%%@*}" ;;
  esac
fi

# Fallback to lockfiles
if [[ -z "$pm" ]]; then
  if   [[ -f "bun.lock"      || -f "bun.lockb"        ]]; then pm="bun"
  elif [[ -f "pnpm-lock.yaml"                          ]]; then pm="pnpm"
  elif [[ -f "yarn.lock"                               ]]; then pm="yarn"
  elif [[ -f "package-lock.json"                       ]]; then pm="npm"
  fi
fi

# Determine formatter — only biome is supported in v1
has_biome=false
if [[ -f "biome.json" || -f "biome.jsonc" ]]; then
  has_biome=true
elif command -v jq >/dev/null 2>&1; then
  # devDependencies fallback
  if jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"]' package.json >/dev/null 2>&1; then
    has_biome=true
  fi
fi

case "$pm" in
  bun)
    $has_biome && emit "bun-biome"  "package.json + bun + biome"
    emit "unknown" "bun detected but biome is missing — only biome stacks are supported in v1"
    ;;
  pnpm)
    $has_biome && emit "pnpm-biome" "package.json + pnpm + biome"
    emit "unknown" "pnpm detected but biome is missing — only biome stacks are supported in v1"
    ;;
  npm|yarn|"")
    emit "unknown" "package manager '$pm' is not supported (only bun and pnpm in v1)"
    ;;
esac

emit "unknown" "fall-through (should not happen)"
