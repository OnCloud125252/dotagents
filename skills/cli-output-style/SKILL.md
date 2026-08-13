---
name: cli-output-style
description: "CLI output style guide for writing shell scripts and commands with consistent colors, symbols, dividers, and formatting. Use this skill whenever writing or modifying shell scripts that produce terminal output — CLI tools, setup scripts, health checks, status dashboards, deployment scripts, or any bash/zsh program that prints colored or structured output to the user. Also triggers when the user asks about terminal formatting, ANSI colors, CLI UX patterns, stripping ANSI color when output is piped or redirected, TTY / isatty / NO_COLOR / CLICOLOR_FORCE detection, or how to make shell output look professional and consistent."
user-invocable: false
---

# CLI Output Style Guide

This skill defines conventions for producing clean, scannable terminal output in shell scripts. Users read CLI output quickly — consistent symbols, colors, and spacing let them spot success, errors, and next steps at a glance.

The patterns below are drawn from a production shell framework (CustomRC) but apply to any bash/zsh CLI tool.

## Foundation: Colors and Symbols

### Color Definitions

Define color variables at the top of your script. Prefix them to avoid collisions with other sourced scripts (e.g., `_CLI_*`, `_MYTOOL_*`).

```bash
_CLI_RED='\033[0;31m'
_CLI_GREEN='\033[0;32m'
_CLI_YELLOW='\033[0;33m'
_CLI_BLUE='\033[0;34m'
_CLI_PURPLE='\033[0;35m'
_CLI_CYAN='\033[0;36m'
_CLI_WHITE='\033[0;37m'
_CLI_GRAY='\033[0;90m'
_CLI_NC='\033[0m'
```

### Semantic Color Mapping

Colors carry consistent meaning — don't mix them up:

| Color | Meaning | Use For |
|---|---|---|
| Green | Success | Completed actions, enabled states, pass indicators |
| Red | Failure | Errors, disabled states, fail indicators |
| Yellow | Warning | Non-fatal issues, caution, advisory |
| Cyan | Info | Categories, informational labels, neutral status |
| Purple | Structure | Headers, dividers, section frames |
| Blue | Values | Paths, URLs, highlighted data |
| Grey | Dim | Disabled states, secondary info, annotations |
| White | Neutral | Labels, plain text |

Always close color spans with `$_CLI_NC` (reset). Unclosed spans bleed color into subsequent output.

### Disable Color When Not a TTY

Color codes that look great in a terminal become noise when they land in a pipe, a log file, `grep`, or another tool's stdin: you get literal `\033[0;32m` sequences scattered through the text. Detect this once, right after defining the color variables, and **null them out** (set to empty string) so every downstream `echo -e "$_CLI_GREEN..."` keeps working unchanged. This gate MUST run before the Symbol Definitions below, because those derive `_CLI_CHECK` / `_CLI_CROSS` / etc. from the color vars.

```bash
# Respect NO_COLOR (https://no-color.org/) and CLICOLOR_FORCE; otherwise gate on stdout being a TTY
if [[ -n "${CLICOLOR_FORCE:-}" ]]; then
  : # color forced on, even when piped
elif [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
  _CLI_RED='' _CLI_GREEN='' _CLI_YELLOW='' _CLI_BLUE=''
  _CLI_PURPLE='' _CLI_CYAN='' _CLI_WHITE='' _CLI_GRAY='' _CLI_NC=''
fi
```

> **Why this pattern?**
> - `[[ ! -t 1 ]]` is true when **stdout (fd 1)** is not a terminal, i.e. the script is piped (`|`) or redirected (`>`, `>>`). That is the moment to suppress color.
> - `NO_COLOR` is the cross-tool de-facto standard (https://no-color.org/): if the env var is set to **any value, including empty**, the user is explicitly asking for no color. `[[ -n "${NO_COLOR:-}" ]]` is a presence check, not a value check.
> - `CLICOLOR_FORCE` is the escape hatch: when set, color stays on even through a pipe (useful for `less -R`, pagers, or wrappers that re-render escapes). Check it first so it wins.
> - **Empty string, not `unset`**: setting the vars to `''` means every `$variable` reference below silently expands to nothing; no `echo -e` line needs to change. The bracket symbols (`[✓]`, `[✗]`, `[!]`, `[i]`) and the `━` divider characters stay visible because they are literal text, not ANSI sequences.
> - Interaction with the width helper above: `[[ ! -t 1 ]]` keys off fd 1, while `tput cols </dev/tty` keys off the controlling terminal. So when piped, color drops but dividers still size to the user's actual terminal — usually what you want.

If a script writes colored output to **stderr** (fd 2) and should respect its own TTY state, gate that path separately with `[[ -t 2 ]]` rather than reusing the fd 1 check.

### Symbol Definitions

Bracketed symbols provide visual anchors at the start of each line. The bracket format `[x]` is compact yet distinct:

```bash
_CLI_CHECK="${_CLI_GREEN}[✓]${_CLI_NC}"
_CLI_CROSS="${_CLI_RED}[✗]${_CLI_NC}"
_CLI_WARN="${_CLI_YELLOW}[!]${_CLI_NC}"
_CLI_INFO="${_CLI_CYAN}[i]${_CLI_NC}"
```

| Symbol | Meaning | When To Use |
|---|---|---|
| `[✓]` green | Success | Action completed, check passed |
| `[✗]` red | Error | Action failed, check failed |
| `[!]` yellow | Warning | Non-fatal issue, advisory |
| `[i]` cyan | Info | Progress update, neutral information |

## Output Functions

Wrap `echo` calls in helper functions — this enforces consistency and makes the code more readable:

```bash
log_info()    { echo -e "$_CLI_INFO $1"; }
log_success() { echo -e "$_CLI_CHECK $1"; }
log_warn()    { echo -e "$_CLI_WARN $1"; }
log_error()   { echo -e "$_CLI_CROSS $1"; }
```

Name these functions with a prefix matching your tool (e.g., `_mytool_info`, `_deploy_success`) to avoid collisions in sourced environments. For standalone scripts, short names like `log_info` work fine.

### Terminal Width

Compute the terminal width **once** at the top of the script — not inside functions. This ensures all dividers render at the same width, even if the shell environment shifts mid-execution (e.g., after subprocesses redirect stdout).

```bash
# Terminal width — compute once; try /dev/tty in a subshell to suppress errors
_CLI_WIDTH="${COLUMNS:-$( (tput cols </dev/tty) 2>/dev/null || tput cols 2>/dev/null || echo 80)}"
```

> **Why this pattern?**
> - `$COLUMNS` is a shell variable, not an environment variable, so child processes (git hooks, subshells, piped scripts) don't inherit it.
> - `tput cols </dev/tty` lets `tput` query the controlling terminal directly, giving the correct width even in non-interactive contexts (git hooks, piped scripts).
> - The `/dev/tty` redirect is wrapped in a **subshell** `( ... ) 2>/dev/null` — if the device is unavailable (CI, cron, non-interactive agents), the shell's "Device not configured" error is captured by the outer stderr redirect instead of leaking to the user.
> - The fallback chain: `$COLUMNS` → `tput cols </dev/tty` → `tput cols` → `80`.

### Divider Function

A divider draws a full-width line with an optional bracketed label — useful for framing command output:

```bash
print_divider() {
  local color="${1:-$_CLI_PURPLE}" label="${2:-}"
  local width="$_CLI_WIDTH"
  if [[ -n "$label" ]]; then
    local padding=$((width - ${#label} - 6))
    local fill
    printf -v fill '%*s' "$padding" ''
    printf '%b━━━━[%s]%s%b\n' "$color" "$label" "${fill// /━}" "$_CLI_NC"
  else
    local fill
    printf -v fill '%*s' "$width" ''
    printf '%b%s%b\n' "$color" "${fill// /━}" "$_CLI_NC"
  fi
}
```

Output:
```
━━━━[Deploy Status]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Command Structure Patterns

### Framed Command

Wrap significant command output in opening/closing dividers. The empty lines provide breathing room:

```bash
my_status_command() {
  echo ""
  print_divider "$_CLI_PURPLE" "Service Status"
  echo ""

  # ... body ...

  echo ""
  print_divider "$_CLI_PURPLE"
  echo ""
}
```

### Key-Value Display

Two-space indent. Align colons for readability. Color the values, not the labels:

```bash
echo -e "  Version:     ${_CLI_CYAN}2.1.0${_CLI_NC}"
echo -e "  Status:      ${_CLI_GREEN}running${_CLI_NC}"
echo -e "  Uptime:      ${_CLI_BLUE}3d 14h${_CLI_NC}"
echo -e "  Debug:       ${_CLI_GRAY}disabled${_CLI_NC}"
```

Output:
```
  Version:     2.1.0
  Status:      running
  Uptime:      3d 14h
  Debug:       disabled
```

### Category-Grouped Lists

Categories in cyan with trailing slash. Items indented 4 spaces with status symbols:

```bash
echo -e "  ${_CLI_CYAN}Services/${_CLI_NC}"
echo -e "    ${_CLI_GREEN}✓${_CLI_NC} api-server"
echo -e "    ${_CLI_GREEN}✓${_CLI_NC} worker"
echo -e "    ${_CLI_RED}✗${_CLI_NC} scheduler ${_CLI_GRAY}(stopped)${_CLI_NC}"
```

Output:
```
  Services/
    ✓ api-server
    ✓ worker
    ✗ scheduler (stopped)
```

### Multi-Step Progress

Show each stage with info messages. Conclude with success or error:

```bash
log_info "Connecting to database..."
log_info "Running migrations (3 pending)..."
log_info "Seeding test data..."
log_success "Database setup complete"
```

Output:
```
[i] Connecting to database...
[i] Running migrations (3 pending)...
[i] Seeding test data...
[✓] Database setup complete
```

### Health Checks

Use check/cross symbols for pass/fail. Group related checks:

```bash
log_success "Config file exists: /etc/myapp/config.yml"
log_success "Database connection OK"
log_error "Redis unreachable: connection refused"
echo ""
log_info "Checking permissions..."
log_success "Log directory writable"
log_warn "Cache directory missing, will be created"
```

### Conditional Results

Branch on operation outcome with matching output:

```bash
if deploy_service "$name"; then
  log_success "Deployed $name"
else
  log_error "Failed to deploy $name"
  return 1
fi
```

### Actionable Follow-Ups

When a command finishes but the user needs to act, pair success with info:

```bash
log_success "SSL certificate renewed"
log_info "Run 'nginx -s reload' to apply"
```

### Warning With Recovery Guidance

When something is wrong but not fatal, warn and suggest a fix:

```bash
log_warn "Cache directory not found"
log_info "Run '$0 init' to create it"
```

## Spacing Rules

- Empty line before and after every divider
- Empty line between logical sections within a framed command
- Two-space indent for nested content (key-value pairs)
- Four-space indent for list items under a category
- No trailing blank lines at end of function output

## Inline Value Highlighting

Color individual values within a line using inline codes. Use the semantic color that matches the value's meaning:

```bash
echo -e "  Branch: ${_CLI_CYAN}main${_CLI_NC} (${_CLI_GREEN}clean${_CLI_NC})"
echo -e "  Path:   ${_CLI_BLUE}/var/log/myapp${_CLI_NC}"
echo -e "  Mode:   ${_CLI_GRAY}disabled${_CLI_NC}"
```

## Checklist: Adding a New Command

1. Define color variables (or reuse existing ones) — prefix to avoid collision
2. Gate color with the TTY / `NO_COLOR` / `CLICOLOR_FORCE` check — run it before deriving symbols so they pick up the (possibly nulled) color vars
3. Define symbol variables (`_CLI_CHECK`, `_CLI_CROSS`, etc.) from the color vars
4. Create `log_info`, `log_success`, `log_warn`, `log_error` helper functions
5. Frame output with dividers (open with label, close without) for status-type commands
6. Use `log_info` for progress steps, `log_success`/`log_error` for outcomes
7. Use `log_warn` + `log_info` for recoverable issues with guidance
8. Color inline values semantically — cyan for data, green for success states, grey for disabled
9. Maintain 2-space indent for key-value pairs, 4-space for list items
10. Return 1 on errors, 0 on success
