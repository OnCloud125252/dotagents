#!/usr/bin/env bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Git Hooks Init Script — pnpm + biome stack
# Configures core.hooksPath and verifies tool dependencies.
# Creates .claude/.githooks-initialized only on full success.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -u

_CLI_RED='\033[0;31m'
_CLI_GREEN='\033[0;32m'
_CLI_YELLOW='\033[0;33m'
_CLI_CYAN='\033[0;36m'
_CLI_GRAY='\033[0;90m'
_CLI_PURPLE='\033[0;35m'
_CLI_NC='\033[0m'

_CLI_WIDTH="${COLUMNS:-$( (tput cols </dev/tty) 2>/dev/null || tput cols 2>/dev/null || echo 80)}"

_CLI_CHECK="${_CLI_GREEN}[✓]${_CLI_NC}"
_CLI_CROSS="${_CLI_RED}[✗]${_CLI_NC}"
_CLI_WARN="${_CLI_YELLOW}[!]${_CLI_NC}"
_CLI_INFO="${_CLI_CYAN}[i]${_CLI_NC}"

log_info()    { echo -e "$_CLI_INFO $1"; }
log_success() { echo -e "$_CLI_CHECK $1"; }
log_warn()    { echo -e "$_CLI_WARN $1"; }
log_error()   { echo -e "$_CLI_CROSS $1"; }

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

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
  log_error "Not inside a git repository."
  exit 1
fi
cd "$REPO_ROOT"

echo ""
print_divider "$_CLI_PURPLE" "Hook Setup (pnpm + biome)"
echo ""

declare -a MISSING_TOOLS=()

check_tool() {
  local name="$1" install_hint="$2" version_cmd="${3:-}"
  if command -v "$name" >/dev/null 2>&1; then
    local version=""
    if [[ -n "$version_cmd" ]]; then
      version=$(eval "$version_cmd" 2>/dev/null | head -n 1)
    fi
    if [[ -n "$version" ]]; then
      log_success "${name} ${_CLI_GRAY}(${version})${_CLI_NC}"
    else
      log_success "${name} ${_CLI_GRAY}(installed)${_CLI_NC}"
    fi
  else
    log_error "${name} ${_CLI_RED}not found${_CLI_NC} — ${install_hint}"
    MISSING_TOOLS+=("$name|$install_hint")
  fi
}

log_info "Checking tool dependencies..."
echo ""

check_tool "pnpm" "https://pnpm.io/installation — corepack enable && corepack prepare pnpm@latest --activate" "pnpm --version"
check_tool "node" "Node.js is required by pnpm. https://nodejs.org or use nvm/fnm." "node --version"
check_tool "git"  "git is required" "git --version"
check_tool "jq"   "brew install jq (used to detect optional package.json scripts)" "jq --version"

if pnpm exec biome --version >/dev/null 2>&1; then
  log_success "biome ${_CLI_GRAY}($(pnpm exec biome --version 2>/dev/null | head -n 1))${_CLI_NC}"
else
  log_error "biome ${_CLI_RED}not available via pnpm exec${_CLI_NC} — add @biomejs/biome to devDependencies and run \`pnpm install\`"
  MISSING_TOOLS+=("biome|pnpm add -D @biomejs/biome")
fi

if [[ -f ".gitleaks.toml" ]]; then
  check_tool "gitleaks" "brew install gitleaks (.gitleaks.toml present so it is required)" "gitleaks version"
else
  log_info "gitleaks ${_CLI_GRAY}(skipped — no .gitleaks.toml in repo)${_CLI_NC}"
fi

echo ""

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
  log_error "${#MISSING_TOOLS[@]} required tool(s) missing — initialization aborted."
  echo ""
  log_info "Install the following before re-running this script:"
  echo ""
  for entry in "${MISSING_TOOLS[@]}"; do
    local_name="${entry%%|*}"
    local_hint="${entry#*|}"
    echo -e "  ${_CLI_RED}•${_CLI_NC} ${_CLI_CYAN}${local_name}${_CLI_NC} → ${local_hint}"
  done
  echo ""
  log_info "Then run: ${_CLI_CYAN}scripts/setup-hooks.sh${_CLI_NC}"
  echo ""
  print_divider "$_CLI_RED"
  echo ""
  exit 1
fi

CURRENT_HOOKS_PATH=$(git config --local core.hooksPath 2>/dev/null || true)
if [[ -n "$CURRENT_HOOKS_PATH" && "$CURRENT_HOOKS_PATH" != ".githooks" ]]; then
  log_warn "core.hooksPath is currently ${_CLI_YELLOW}${CURRENT_HOOKS_PATH}${_CLI_NC}; overriding with ${_CLI_CYAN}.githooks${_CLI_NC}"
fi

if git config --local core.hooksPath .githooks; then
  log_success "core.hooksPath set to ${_CLI_CYAN}.githooks${_CLI_NC}"
else
  log_error "Failed to set core.hooksPath"
  exit 1
fi

if [[ -d .githooks ]]; then
  chmod +x .githooks/* 2>/dev/null || true
fi

mkdir -p .claude
touch .claude/.githooks-initialized

echo ""
log_success "Initialization marker created at ${_CLI_CYAN}.claude/.githooks-initialized${_CLI_NC}"
echo ""
print_divider "$_CLI_PURPLE"
echo ""
log_success "Git hooks ready. The following hooks are now active:"
echo -e "  ${_CLI_GRAY}•${_CLI_NC} pre-commit  — gitleaks (if configured) + biome --write on staged files"
echo -e "  ${_CLI_GRAY}•${_CLI_NC} pre-push    — gitleaks + pnpm run check + tsc --noEmit + pnpm test (if defined)"
echo ""
