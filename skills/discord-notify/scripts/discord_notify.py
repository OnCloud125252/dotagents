#!/usr/bin/env python3
"""Send task notifications to a Discord forum channel via webhook.

The first call for a given ``--key`` creates a new forum post (thread); every
later call with the same ``--key`` appends a follow-up message to that same post.
This maps directly onto the two intended usages:

  * "notify me when done"            -> one call (create the post, that is it)
  * "notify me on important progress" -> first checkpoint creates the post,
                                         later checkpoints append to it

Configuration (single Discord forum channel):
  * Webhook URL : ~/.agents/discord-notify/webhook.url   (one line, the secret)
  * State       : ~/.agents/discord-notify/state.json    (key -> thread mapping)

Only the Python standard library is used, so no ``pip install`` step is needed.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

CONFIG_DIR = Path.home() / ".agents" / "discord-notify"
DEFAULT_WEBHOOK_FILE = CONFIG_DIR / "webhook.url"
DEFAULT_STATE_FILE = CONFIG_DIR / "state.json"

CONTENT_LIMIT = 2000
THREAD_NAME_LIMIT = 100
DEFAULT_USERNAME = "Claude Code"
TIMESTAMP_FORMAT = "%Y/%m/%d %H:%M:%S"
USER_AGENT = "discord-notify-skill (https://github.com/OnCloud125252/dotagents, 1.0)"

EXIT_OK = 0
EXIT_REMOTE = 1
EXIT_CONFIG = 2


class ConfigError(Exception):
    """Raised for missing/invalid local configuration or arguments."""


class DiscordError(Exception):
    """Raised when Discord returns a non-success response."""

    def __init__(self, status: int | None, body: str) -> None:
        self.status = status
        self.body = body
        super().__init__(self._describe())

    def _describe(self) -> str:
        detail = self.body.strip()
        try:
            parsed = json.loads(detail)
            detail = parsed.get("message", detail)
            if "code" in parsed:
                detail = f"{detail} (code {parsed['code']})"
        except (ValueError, AttributeError):
            pass
        prefix = f"HTTP {self.status}" if self.status is not None else "request failed"
        return f"Discord {prefix}: {detail}"


def read_webhook(webhook_file: Path) -> str:
    if not webhook_file.exists():
        raise ConfigError(
            f"webhook not configured: {webhook_file} does not exist.\n"
            "Create a webhook on your Discord forum channel and write its URL "
            "into that file (single line). See references/setup.md."
        )
    url = webhook_file.read_text(encoding="utf-8").strip()
    if not url:
        raise ConfigError(f"webhook file is empty: {webhook_file}")
    if not url.startswith("https://"):
        raise ConfigError(f"webhook URL looks invalid (must start with https://): {webhook_file}")
    return url


def load_state(state_file: Path) -> dict:
    if not state_file.exists():
        return {"guild_id": None, "keys": {}}
    try:
        data = json.loads(state_file.read_text(encoding="utf-8"))
    except ValueError:
        return {"guild_id": None, "keys": {}}
    data.setdefault("guild_id", None)
    data.setdefault("keys", {})
    return data


def save_state(state_file: Path, state: dict) -> None:
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def split_message(text: str, limit: int = CONTENT_LIMIT) -> list[str]:
    """Split text into <=limit-char chunks, preferring newline boundaries."""
    text = text.rstrip("\n")
    if not text:
        return []
    if len(text) <= limit:
        return [text]
    chunks: list[str] = []
    remaining = text
    while len(remaining) > limit:
        window = remaining[:limit]
        cut = window.rfind("\n")
        if cut < limit // 2:  # newline too early (or absent) -> hard cut
            cut = limit
        chunks.append(remaining[:cut].rstrip("\n"))
        remaining = remaining[cut:].lstrip("\n")
    if remaining:
        chunks.append(remaining)
    return chunks


def build_thread_name(title: str, timestamp: str) -> str:
    suffix = f" - {timestamp}"
    room = THREAD_NAME_LIMIT - len(suffix)
    title = title.strip()
    if len(title) > room:
        title = title[: room - 1].rstrip() + "…"
    return f"{title}{suffix}"


def _query_join(url: str) -> str:
    return "&" if "?" in url else "?"


def _retry_after_seconds(body: str) -> float:
    try:
        return float(json.loads(body).get("retry_after", 1.0))
    except (ValueError, AttributeError, TypeError):
        return 1.0


def _request(url: str, method: str = "GET", payload: dict | None = None, max_retries: int = 3):
    data = None
    headers = {"User-Agent": USER_AGENT}
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    for attempt in range(max_retries + 1):
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request) as response:
                body = response.read().decode("utf-8")
                if response.status == 204 or not body:
                    return None
                return json.loads(body)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", "replace")
            if exc.code == 429 and attempt < max_retries:
                time.sleep(min(_retry_after_seconds(body), 10.0))
                continue
            raise DiscordError(exc.code, body)
        except urllib.error.URLError as exc:
            raise DiscordError(None, f"network error: {exc.reason}")
    raise DiscordError(429, "rate limited: retries exhausted")


def fetch_guild_id(webhook_url: str) -> str | None:
    try:
        webhook = _request(webhook_url, method="GET")
    except DiscordError:
        return None
    return webhook.get("guild_id") if webhook else None


def build_post_url(guild_id: str | None, thread_id: str) -> str | None:
    if guild_id and thread_id:
        return f"https://discord.com/channels/{guild_id}/{thread_id}"
    return None


def create_post(webhook_url: str, thread_name: str, content: str, username: str, tags: list[str]) -> str:
    payload = {"thread_name": thread_name, "content": content, "username": username}
    if tags:
        payload["applied_tags"] = tags
    url = f"{webhook_url}{_query_join(webhook_url)}wait=true"
    message = _request(url, method="POST", payload=payload)
    if not message or "channel_id" not in message:
        raise DiscordError(None, "unexpected response: missing channel_id (thread id)")
    return message["channel_id"]  # starter message's channel_id is the new thread id


def append_message(webhook_url: str, thread_id: str, content: str, username: str) -> None:
    url = f"{webhook_url}{_query_join(webhook_url)}thread_id={thread_id}&wait=true"
    _request(url, method="POST", payload={"content": content, "username": username})


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="discord_notify.py",
        description="Notify a Discord forum channel: create a post, or append to an existing one.",
    )
    parser.add_argument("--key", required=True, help="Stable task key. Same key = same forum post.")
    parser.add_argument("--title", help="Descriptive post title (used only when creating the post; the script appends ' - <timestamp>').")
    parser.add_argument("-m", "--message", help="Message text. Use '-' or omit to read from stdin (best for long/multi-line summaries).")
    parser.add_argument("--username", default=DEFAULT_USERNAME, help=f"Display name override (default: {DEFAULT_USERNAME}).")
    parser.add_argument("--tags", help="Comma-separated Discord forum tag IDs to apply (create only).")
    parser.add_argument("--new", action="store_true", help="Force a fresh post even if --key already has one.")
    parser.add_argument("--webhook-file", type=Path, default=DEFAULT_WEBHOOK_FILE, help=argparse.SUPPRESS)
    parser.add_argument("--webhook-url", help=argparse.SUPPRESS)
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE_FILE, help=argparse.SUPPRESS)
    parser.add_argument("--dry-run", action="store_true", help="Print what would be sent without calling Discord or writing state.")
    return parser.parse_args(argv)


def resolve_message(raw: str | None) -> str:
    if raw is not None and raw != "-":
        return raw
    if raw == "-" or not sys.stdin.isatty():
        return sys.stdin.read()
    return ""


def run(argv: list[str]) -> int:
    args = parse_args(argv)

    message = resolve_message(args.message).rstrip("\n")
    chunks = split_message(message)
    if not chunks:
        raise ConfigError("message is empty: pass --message or pipe text via stdin.")

    tags = [t.strip() for t in args.tags.split(",")] if args.tags else []
    tags = [t for t in tags if t]

    state = load_state(args.state_file)
    entry = state["keys"].get(args.key)
    creating = args.new or entry is None

    if creating and not args.title:
        raise ConfigError(
            f"no post exists yet for --key '{args.key}', so --title is required to create one."
        )

    if args.dry_run:
        return _dry_run(args, state, entry, creating, chunks, tags)

    webhook_url = args.webhook_url or read_webhook(args.webhook_file)

    if creating:
        timestamp = datetime.now().strftime(TIMESTAMP_FORMAT)
        thread_name = build_thread_name(args.title, timestamp)
        thread_id = create_post(webhook_url, thread_name, chunks[0], args.username, tags)
        for chunk in chunks[1:]:
            append_message(webhook_url, thread_id, chunk, args.username)

        guild_id = state.get("guild_id") or fetch_guild_id(webhook_url)
        if guild_id:
            state["guild_id"] = guild_id
        post_url = build_post_url(guild_id, thread_id)

        state["keys"][args.key] = {
            "thread_id": thread_id,
            "title": args.title,
            "thread_name": thread_name,
            "created_at": timestamp,
            "message_count": len(chunks),
            "post_url": post_url,
        }
        save_state(args.state_file, state)

        print(f"✓ Created Discord forum post for key '{args.key}'")
        print(f"  title    : {thread_name}")
        print(f"  thread_id: {thread_id}")
        if post_url:
            print(f"  url      : {post_url}")
        if len(chunks) > 1:
            print(f"  messages : {len(chunks)} (summary was split to fit the 2000-char limit)")
        return EXIT_OK

    thread_id = entry["thread_id"]
    for chunk in chunks:
        append_message(webhook_url, thread_id, chunk, args.username)
    entry["message_count"] = entry.get("message_count", 0) + len(chunks)
    save_state(args.state_file, state)

    print(f"✓ Appended to existing post for key '{args.key}'")
    print(f"  title    : {entry.get('thread_name', entry.get('title', ''))}")
    print(f"  thread_id: {thread_id}")
    if entry.get("post_url"):
        print(f"  url      : {entry['post_url']}")
    if len(chunks) > 1:
        print(f"  messages : +{len(chunks)} (this update was split to fit the 2000-char limit)")
    return EXIT_OK


def _dry_run(args, state, entry, creating, chunks, tags) -> int:
    print("[dry-run] no Discord request will be sent, no state written")
    if creating:
        timestamp = datetime.now().strftime(TIMESTAMP_FORMAT)
        thread_name = build_thread_name(args.title, timestamp)
        print(f"[dry-run] mode      : CREATE post for key '{args.key}'")
        print(f"[dry-run] thread    : {thread_name!r} (len={len(thread_name)})")
        print(f"[dry-run] username  : {args.username}")
        if tags:
            print(f"[dry-run] tags      : {tags}")
    else:
        print(f"[dry-run] mode      : APPEND to key '{args.key}' (thread_id={entry['thread_id']})")
    print(f"[dry-run] chunks    : {len(chunks)} (limit {CONTENT_LIMIT} chars each)")
    for index, chunk in enumerate(chunks, start=1):
        print(f"[dry-run]   chunk {index}: {len(chunk)} chars")
    return EXIT_OK


def main() -> int:
    try:
        return run(sys.argv[1:])
    except ConfigError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_CONFIG
    except DiscordError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_REMOTE


if __name__ == "__main__":
    raise SystemExit(main())
