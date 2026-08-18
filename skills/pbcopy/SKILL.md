---
name: pbcopy
description: Copy output to the macOS clipboard via `pbcopy`. Trigger when the user appends or includes `/pbcopy` anywhere in their prompt — it is a suffix flag on a normal request, not a standalone command. Supports optional override flags `/pbcopy full` (copy entire response verbatim) and `/pbcopy raw` (copy only the literal output of commands/tools you ran). With no flag, pick the substantive artifact (logs, JSON, code, generated text, or the whole answer when the answer IS the artifact) and skip conversational framing.
argument-hint: "[instruction for the agent to select content]"
disable-model-invocation: true
user-invocable: true
---

# pbcopy

Inline modifier: when the user includes `/pbcopy` in a prompt, copy the relevant output of your response to the macOS clipboard.

## How to recognize it

`/pbcopy` is a suffix flag, not a command. Examples:

- `what is today's weather? /pbcopy`
- `what is the docker log of this server? /pbcopy`
- `/pbcopy generate a commit message for these changes`
- `what is the docker log of this server? /pbcopy full`

Treat the rest of the prompt as the real task. After answering, perform the copy step.

## What to copy

The token immediately after `/pbcopy` (if any) selects the mode:

### Default — `/pbcopy` with no flag

Copy the substantive artifact, agent's best judgment:

- If they asked for a specific artifact (logs, JSON, a file's contents, code, a generated message) → copy **only** that artifact, verbatim. No surrounding prose. No "Here's the log:" framing. No markdown code fences that you added as formatting (the fences are presentation, not content).
- If the answer itself **is** the artifact (a short factual answer, a paragraph) → copy the whole answer text.
- Never copy your conversational wrapping ("Sure, here you go:", "Copied below:", trailing "Let me know if…").

When in doubt, prefer the narrower selection — the user can re-run with `full` if they wanted more.

### `/pbcopy full`

Copy **everything** Claude produced in this turn, verbatim — prose, framing, artifacts, all of it. Use when the user is overriding the smart default because it would have narrowed too aggressively.

The full text is whatever the user will see in the terminal as your response, in reading order. Tool-call internals are not part of the response — only the user-visible message text.

### `/pbcopy raw`

Copy **only** the literal stdout/stderr of commands or tools the agent ran during this turn, with no agent-authored text mixed in. Use when even the smart default includes too much framing.

- If exactly one command ran, copy its full output verbatim.
- If multiple commands ran, concatenate their outputs in encounter order with no separators, headers, or annotations added.
- If no commands ran, fall back to the smart default and tell the user one short line ("`raw` requested but no command output captured — copied artifact instead.").

## How to copy (safe forms only)

Always pipe via stdin to preserve newlines, quotes, and backslashes. Pick the form that matches the source:

- Content already on disk: `pbcopy < /path/to/file`
- Output of another command: `<cmd> | pbcopy`
- Inline string with arbitrary content: use a **single-quoted** heredoc so nothing inside is expanded:

  ```sh
  cat <<'PBCOPY_EOF' | pbcopy
  ...content here, verbatim, multi-line ok...
  PBCOPY_EOF
  ```

Do **not** use `echo "..." | pbcopy` or `printf "..." | pbcopy` for arbitrary content — they mangle backslashes, dollar signs, and embedded quotes.

If the content might contain the literal string `PBCOPY_EOF`, pick a different unique delimiter.

## After copying

Confirm with one short line that names the mode used, e.g. `Copied to clipboard (default).` / `Copied to clipboard (full, N lines).` / `Copied to clipboard (raw).`. Do not re-print the copied content.

## Constraints

- `pbcopy` is macOS-only. If you're operating on a remote Linux host (over ssh, in a container), this skill does not apply — say so and stop, do not silently substitute `xclip`/`wl-copy` unless the user has indicated they want the remote-host clipboard.
- Copy verbatim. Do not trim, reformat, strip trailing newlines beyond what the source has, or "clean up" the content.
- The copy step must not silently fail. If `pbcopy` errors, surface it.
