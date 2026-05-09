#!/usr/bin/env bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Zeabur Backend — Git Hooks Init Script
# Configures core.hooksPath and verifies all tool dependencies.
# Creates .claude/.githooks-initialized only on full success.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -u

# Colors
_CLI_RED='\033[0;31m'
_CLI_GREEN='\033[0;32m'
_CLI_YELLOW='\033[0;33m'
_CLI_CYAN='\033[0;36m'
_CLI_GRAY='\033[0;90m'
_CLI_PURPLE='\033[0;35m'
_CLI_NC='\033[0m'

# Terminal width
_CLI_WIDTH="${COLUMNS:-$( (tput cols </dev/tty) 2>/dev/null || tput cols 2>/dev/null || echo 80)}"

# Symbols
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

# ── Locate repo root ─────────────────────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
  log_error "Not inside a git repository."
  exit 1
fi
cd "$REPO_ROOT"

echo ""
print_divider "$_CLI_PURPLE" "Hook Setup"
echo ""

# ── Tool dependency checks ───────────────────────────────────────
declare -a MISSING_TOOLS=()

check_tool() {
  local name="$1"
  local install_hint="$2"
  local version_cmd="${3:-}"

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

check_tool "gitleaks"           "brew install gitleaks"                                                  "gitleaks version"
check_tool "golangci-lint"      "brew install golangci-lint"                                             "golangci-lint --version"
check_tool "gofmt"              "comes with Go — see docs/environment-setup.md"
check_tool "protoc"             "see docs/environment-setup.md"                                          "protoc --version"
check_tool "protoc-gen-go"      "go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.1"        "protoc-gen-go --version"
check_tool "protoc-gen-go-grpc" "go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0"        "protoc-gen-go-grpc --version"

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

# ── Configure core.hooksPath ─────────────────────────────────────
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

# Make hook files executable (idempotent)
if [[ -d .githooks ]]; then
  chmod +x .githooks/* 2>/dev/null || true
fi

# ── Marker file (only on full success) ───────────────────────────
mkdir -p .claude
touch .claude/.githooks-initialized

echo ""
log_success "Initialization marker created at ${_CLI_CYAN}.claude/.githooks-initialized${_CLI_NC}"
echo ""
print_divider "$_CLI_PURPLE"
echo ""
log_success "Git hooks ready. The following hooks are now active:"
echo -e "  ${_CLI_GRAY}•${_CLI_NC} pre-commit  — gitleaks + gofmt auto-fix"
echo -e "  ${_CLI_GRAY}•${_CLI_NC} pre-push    — gitleaks + golangci-lint --fix + go build"
echo -e "  ${_CLI_GRAY}•${_CLI_NC} post-merge  — go mod download / make grpc / make graphql"
echo ""
