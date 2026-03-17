#!/bin/bash
# Summarize a message using OpenAI gpt-4.1-nano with structured output.
# Uses function calling with strict schema to guarantee valid JSON output.
# Usage: echo "long message" | ./summarize.sh <stop|notification> [user_input]
# Output: JSON with "subtitle" and "message" fields.
# Requires: CLAUDE_CODE_SUMMARIZER_API_KEY env var
# Falls back to defaults if the API key is missing or the call fails.

EVENT_TYPE="${1:-stop}"
USER_INPUT="${2:-}"
OPENAI_API_KEY="${CLAUDE_CODE_SUMMARIZER_API_KEY:-}"

MAX_INPUT_CHARS=2500

input=$(cat)
if [ -z "$input" ]; then
  exit 0
fi
input=$(echo "$input" | head -c "$MAX_INPUT_CHARS")

# Fallback: return default JSON without calling the API
fallback() {
  local default_subtitle
  default_subtitle=$(echo "$input" | head -c 30 | tr '\n' ' ')
  jq -n --arg s "$default_subtitle" --arg m "$input" '{"subtitle":$s,"message":$m}'
  exit 0
}

if [ -z "$OPENAI_API_KEY" ]; then
  fallback
fi

# Build JSON payload using jq for safe escaping
user_context=""
if [ -n "$USER_INPUT" ]; then
  user_context="User asked: ${USER_INPUT}\n\n"
fi

payload=$(jq -n \
  --arg msg "$input" \
  --arg event "$EVENT_TYPE" \
  --arg ctx "$user_context" \
  '{
    model: "gpt-4.1-nano",
    messages: [
      {
        role: "system",
        content: "You generate concise notification text for a coding agent. Report work done without using \"I\". Use the shortest sentence possible."
      },
      {
        role: "user",
        content: ($ctx + "event: " + $event + "\n\n" + $msg)
      }
    ],
    tools: [
      {
        type: "function",
        function: {
          name: "send_notification",
          description: "Send a structured notification summary.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              subtitle: {
                type: "string",
                description: "1-4 word brief description in title case (e.g. Notification Hook, Auth Redirect, Database Migration)."
              },
              message: {
                type: "string",
                description: "One sentence detail summary without I, as short as possible (e.g. Added summarization and filtering to notification messages.)."
              }
            },
            required: ["subtitle", "message"],
            additionalProperties: false
          }
        }
      }
    ],
    tool_choice: {
      type: "function",
      function: { name: "send_notification" }
    },
    max_tokens: 120,
    temperature: 0.3
  }')

response=$(curl -s --max-time 10 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "$payload" \
  "https://api.openai.com/v1/chat/completions")

# Extract structured output from function call arguments
result=$(echo "$response" | jq -r '.choices[0].message.tool_calls[0].function.arguments // empty' 2>/dev/null)

# Verify it's valid JSON with both fields
if echo "$result" | jq -e '.subtitle and .message' >/dev/null 2>&1; then
  echo "$result"
else
  fallback
fi
