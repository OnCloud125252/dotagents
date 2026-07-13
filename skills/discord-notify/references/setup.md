# One-time setup: Discord forum webhook

The skill posts to a single Discord **forum channel** through a webhook URL kept in a local file.
This is a one-time setup per machine.

## 1. Requirements

- A Discord server where you have the **Manage Webhooks** permission.
- A **Forum** channel (channel type "Forum"), not a normal text channel.
  The skill creates posts by sending `thread_name`, which Discord only accepts for forum or media channels.

## 2. Create the webhook

1. Open the target forum channel's settings (hover the channel, click the gear, or right-click then **Edit Channel**).
2. Go to **Integrations** then **Webhooks**.
3. Click **New Webhook** (or **Create Webhook**).
4. Optionally rename it; the avatar/name here is just a default.
   Each message overrides the display name to `Claude Code`.
5. Click **Copy Webhook URL**.

## 3. Save the URL to the config file

The URL is a secret: anyone who has it can post to that channel.
It lives under `~/.agents/`, which is a git repo, so the path is gitignored and never committed.
Lock down its permissions too.

```bash
mkdir -p ~/.agents/discord-notify
printf '%s\n' '<paste-your-webhook-url-here>' > ~/.agents/discord-notify/webhook.url
chmod 600 ~/.agents/discord-notify/webhook.url
```

## 4. Verify it works

This sends a real test post to the channel:

```bash
python3 ~/.claude/skills/discord-notify/scripts/discord_notify.py \
  --key setup-test --title "discord-notify 設定測試" -m "✅ Webhook 設定成功。"
```

On success it prints the post title, `thread_id`, and (when resolvable) a clickable post URL.
You can delete that test post in Discord afterward.

## Gotchas

- **Must be a forum/media channel.**
  Pointing the webhook at a normal text channel makes post creation fail, because `thread_name` is rejected there.
- **Forums that require a tag.**
  If the forum is set to require members to pick a tag when posting, webhook creation fails until you pass tag IDs via `--tags <id>,<id>`, or you relax that requirement in the forum's settings.
- **Rotating a leaked URL.**
  Delete the webhook in Discord and create a new one, then overwrite `webhook.url`.
- **Changing channels.**
  This config targets one forum channel.
  To notify a different channel, replace the URL with a webhook belonging to that channel.

## State file

`~/.agents/discord-notify/state.json` maps each `--key` to the post it created (thread id, title, message count).
It is safe to delete: doing so makes the skill "forget" past posts, so a reused key will start a fresh post next time.
