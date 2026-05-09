#!/usr/bin/env bash
# Shared CLI output helpers — INLINED into every generated hook at scaffold time.
# This file is NOT sourced at runtime by hooks; it's a reference snippet so the
# templates stay consistent. If you change anything here, update every template.

_CLI_RED='\033[0;31m'
_CLI_GREEN='\033[0;32m'
_CLI_YELLOW='\033[0;33m'
_CLI_BLUE='\033[0;34m'
_CLI_PURPLE='\033[0;35m'
_CLI_CYAN='\033[0;36m'
_CLI_GRAY='\033[0;90m'
_CLI_NC='\033[0m'

_CLI_WIDTH="${COLUMNS:-$( (tput cols </dev/tty) 2>/dev/null || tput cols 2>/dev/null || echo 80)}"

_CLI_CHECK="${_CLI_GREEN}[✓]${_CLI_NC}"
_CLI_CROSS="${_CLI_RED}[✗]${_CLI_NC}"
_CLI_WARN="${_CLI_YELLOW}[!]${_CLI_NC}"
_CLI_INFO="${_CLI_CYAN}[i]${_CLI_NC}"
_CLI_SKIP="${_CLI_GRAY}[–]${_CLI_NC}"

log_info()    { echo -e "$_CLI_INFO $1"; }
log_success() { echo -e "$_CLI_CHECK $1"; }
log_warn()    { echo -e "$_CLI_WARN $1"; }
log_error()   { echo -e "$_CLI_CROSS $1"; }
log_skip()    { echo -e "$_CLI_SKIP $1"; }

print_divider() {
  local color="${1:-$_CLI_PURPLE}" label="${2:-}"
  local width="$_CLI_WIDTH"
  if [[ -n "$label" ]]; then
    local padding=$((width - ${#label} - 6))
    [[ $padding -lt 0 ]] && padding=0
    local fill
    printf -v fill '%*s' "$padding" ''
    printf '%b━━━━[%s]%s%b\n' "$color" "$label" "${fill// /━}" "$_CLI_NC"
  else
    local fill
    printf -v fill '%*s' "$width" ''
    printf '%b%s%b\n' "$color" "${fill// /━}" "$_CLI_NC"
  fi
}
