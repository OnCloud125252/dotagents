# AGENTS.md

## Code Style Preferences

- Use 2 spaces for indentation (not tabs)
- Prefer async/await over promises
- Use meaningful variable names, avoid single letters except for loop indices
- Always use const/let, never use var in JavaScript/TypeScript
- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Be descriptive and avoid abbreviations
- Ensure names reflect purpose
- Avoid using barrel imports

## Testing Requirements

- Prefer TDD workflow (write tests first)
- Run linting and type checking before completing tasks

## Best Practices

- **Always use the LSP** (Language Server Protocol) for code intelligence — leverage go-to-definition, find-references, diagnostics, and symbol lookups instead of relying solely on text search
- When running scripts or commands that depend on the current git worktree, always verify the working directory first. Use `pwd` or check `.git` to confirm you're in the correct location, especially when working with feature branches or worktrees.
- **Prefer deterministic code over AI generation** — if a value (dates, IDs, checksums, etc.) can be computed programmatically, do that instead of letting an AI model generate or guess it

## Development Workflow

- always use `./.claude/worktrees` for creating and managing git worktrees for different branches or features. This keeps the main repository clean and organized while allowing for easy switching between contexts.
- **Always ask clarifying questions** before starting any task when requirements are ambiguous
- Always create a todo list before starting any operation to track tasks and provide visibility
- Always read existing code before ANY process with more than one step
- Follow existing patterns and conventions in the codebase
- **Prefer modifying existing files** over creating new ones
- **Avoid running background tasks** like `bun run dev` - use foreground execution instead for better visibility and control
- **Spawn multiple subagents in parallel** when tasks are independent and can be done concurrently
- Never output "Generated with Claude Code" or "Co-Authored-By" in commit messages
- **Always ask if entitlement is needed** — when implementing a new service or feature, ask the user whether an entitlement check is required before proceeding with the implementation

## Git Workflow

- **Always use merge as the default** for all git operations (e.g., `git pull`, branch integration) — do not rebase unless explicitly requested

## File Operations

- **ALWAYS use `trash` instead of `rm`** for file deletion

## Editing Guidelines

- After making multiple file edits, always verify the changes were applied correctly by reading the modified files before marking a task complete. Check for stale references or incomplete replacements.

## Language Preferences

- When Chinese is mentioned or needed, always use **Traditional Chinese (zh-TW)**

## Local Tooling Notes

- Docker engine: **OrbStack** (`/Applications/OrbStack.app`). `orb start` if `dockerd` not reachable; `orb status` to check.
- Zeabur kubeconfig: `~/.kube/zeabur-config.yml` (default context: `zeabur-system`). Pass via `KUBECONFIG=~/.kube/zeabur-config.yml` for any `kubectl ...` against Zeabur clusters.
- Postgres client (`psql`/`pg_dump`) **not installed locally** — use `docker run --rm -e PGPASSWORD=... postgres:18-alpine psql/pg_dump ...` for production DB ops. Match the major version (Lazco production runs PG 18; older clients may fail or warn). Connect via Tailscale CGNAT IP (e.g., `100.121.119.84:5432` for cloud-infra).

## Docker Gotchas

- **Named-volume perms only seed on creation** — Docker copies the image directory's contents *and* ownership into a named volume on **first creation only**. If the mount path doesn't pre-exist in the image, the volume is created `root:root 0755` and any non-root `USER` hits `EACCES`. Fix in two places: pre-create the dir + `chown` to the runtime UID in the Dockerfile, **and** `docker volume rm <name>` on already-deployed hosts (the Dockerfile fix alone won't repair existing volumes).

## Lazco Infra Hosts

- **TrueNAS storage**（暱稱 **txg**）: `root@151.158.224.11` (`truenas1.txg1.lazco.tw`)，12×6TB RAIDZ2，56C/62GB。Tailscale: **`100.125.32.15`**（hostname `truenas1-txg1`，WG UDP 鎖在 `:41641`）
- **Cloud-infra platform**（暱稱 **cloud infra**）: `root@160.30.99.12` (`dockhand.cloud-infra.lazco.dev`)，32C/756GB。跑 traefik + cloudflared (systemd) + lazco-cloud-* services。Tailscale: **`100.121.119.84`**（hostname `cloud-infra`）
- Compose 集中於 `dockhand:/root/dockhand/dockhand_data/stacks/<agent>/<stack>/compose.yaml`（hawser runtime path on TrueNAS: `/root/hawser/hawser-stacks/<stack>/`，**不會自動 sync**，寫完 SOT 還要去對應 host 跑 `docker compose up -d`）
- Service-to-service 一律走 Tailscale CGNAT IP（不繞公網），admin/internal port 在 firewall 只對 `tailscale0` 介面開放

## TrueNAS SCALE (Goldeye 25.x) Quirks

- `apt` 被刻意禁用，`/` 與 `/usr` 是 ZFS read-only — 第三方軟體一律跑 docker container（**不要**用 `install-dev-tools` 跑生產服務，TrueNAS 升級會洗掉）
- `/usr/bin/mc` 是 **Midnight Commander 不是 MinIO Client** — S3 測試用 `python3 -c "import boto3..."` 或安裝 `aws-cli`
- 系統設定走 `midclt` API：`midclt call system.general.config` / `update '{...}'` / `ui_restart`
- compose 檔不能放 `/opt`（read-only），用 `/root/` 或 dataset 路徑

## Cloudflare WARP Trap (Server)

- **絕對不要在 server 上 `apt install cloudflare-warp`**（會搶 default route，inbound :22/:80/:443 全死，2026-05-03 cloud-infra 踩過）
- `cloudflare-warp` (consumer client) ≠ `WARP Connector` (site-to-site) — 兩個產品同名前綴極易混淆，連 Cloudflare ZT dashboard 也並列
- Server site-to-site 用 **Tailscale**（單一 vendor、單一產品線、不搶 default route）
- 復原：`warp-cli disconnect` 立即恢復；保險再 `apt purge cloudflare-warp`

## Tailscale on TrueNAS

- TrueNAS 不能 apt → 用 `tailscale/tailscale:latest` Docker container
- Compose 必要：`network_mode: host` + `cap_add: [NET_ADMIN, NET_RAW]` + `devices: [/dev/net/tun:/dev/net/tun]`
- State volume 放 dataset（重啟保留 session token，不需重註冊）
- Auth key 用一次後到 admin → Settings → Keys revoke

## ZFS Gotchas

- `echo 0 > /sys/module/zfs/parameters/zfs_arc_max` **不會自動回算 c_max** — 必須顯式給 byte 數（如 `echo 60129542144`）
- fio `direct=1` 在 ZFS 被忽略（ZFS 不支援 O_DIRECT）— 量冷讀要用比 ARC 大的新資料，或 `zfs set primarycache=none <dataset>`
- Pool ALLOC ÷ `zfs list` USED ≈ 1.5 是 RAIDZ2(6) parity overhead，比例對不上是警訊

## Linear MCP

- `save_document` 帶 `id` 是**整份替換**不是 patch — 要重貼完整 content
- `icon` 欄位拒絕任意 emoji（會回 InputValidationError），建議省略
- 內容用真實換行，`\n` literal 字串會被當字面字元

## SSH Inline Python

- SSH heredoc 內跑 Python f-string 帶 escape quote（`f"{b[\"Name\"]}"`）會 SyntaxError — 用 inline 暫存變數，或改 `python3 -c '...'` 單引號 wrap 整段
