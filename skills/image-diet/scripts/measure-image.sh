#!/usr/bin/env bash
# Build an image and report its size + the layers that dominate it, optionally
# as a delta against a previous size. This is the measurement half of every
# stage gate: "what did this change cost / save, and where did it land".
#
# Usage:
#   measure-image.sh -f <dockerfile> -t <tag> [--context <dir>] \
#       [--build-arg K=V ...] [--platform <p>] [--baseline-bytes <n>]
#
# Prints a human summary and a trailing JSON line: {"bytes":N,"human":"...","delta_bytes":D}

set -euo pipefail

dockerfile=""
tag=""
context="."
platform=""
baseline_bytes=""
build_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) dockerfile="$2"; shift 2 ;;
    -t) tag="$2"; shift 2 ;;
    --context) context="$2"; shift 2 ;;
    --platform) platform="$2"; shift 2 ;;
    --baseline-bytes) baseline_bytes="$2"; shift 2 ;;
    --build-arg) build_args+=(--build-arg "$2"); shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$dockerfile" || -z "$tag" ]]; then
  echo "usage: measure-image.sh -f <dockerfile> -t <tag> [--context dir] [--build-arg K=V] [--platform p] [--baseline-bytes n]" >&2
  exit 1
fi

platform_arg=()
[[ -n "$platform" ]] && platform_arg=(--platform "$platform")

echo "▶ building $tag from $dockerfile ..."
docker build "${platform_arg[@]}" -f "$dockerfile" -t "$tag" "${build_args[@]}" "$context" >/dev/null

bytes="$(docker image inspect "$tag" --format '{{.Size}}')"
human="$(docker images "$tag" --format '{{.Size}}' | head -1)"

echo ""
echo "── $tag ── size: $human ($bytes bytes)"
echo "── largest layers ──"
docker history "$tag" --human --format '{{.Size}}\t{{.CreatedBy}}' | grep -vE '^\s*0B' | head -12

delta_json="null"
if [[ -n "$baseline_bytes" ]]; then
  delta=$(( bytes - baseline_bytes ))
  sign="+"; [[ $delta -lt 0 ]] && sign=""
  echo ""
  echo "── delta vs baseline: ${sign}$(( delta / 1024 / 1024 )) MB (${sign}${delta} bytes)"
  delta_json="$delta"
fi

echo ""
echo "{\"bytes\":$bytes,\"human\":\"$human\",\"delta_bytes\":$delta_json}"
