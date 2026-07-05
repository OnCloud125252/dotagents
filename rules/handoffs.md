# Session Handoffs

- When work must transfer across sessions (phase transitions, session replacement, long-running multi-session efforts), write a durable handoff document instead of relying on session memory or peer messages.
- Location: `~/.agents/handoffs/<topic-name>/*.md` (one directory per effort; split large handoffs into multiple files).
- Never place handoffs in a session scratchpad or `/tmp` (session-scoped, lost on close) or inside a repo working tree (pollutes the project).
- A handoff must be readable standalone: state the authority model (grants are session-bound and never transfer), the verified baseline (branch/commit), open items with owners, and pointers to canonical records (tracker issues, design docs) rather than duplicating them.
- Mark uncertain facts as unverified; a successor must re-verify load-bearing claims instead of inheriting them as truth.
- The successor session's first action is to read the handoff top-to-bottom before touching any state it describes.
