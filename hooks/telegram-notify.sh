#!/bin/bash
# Telegram notification hook for Claude Code pipeline events.
# Reads pipeline context from .tasks/.pipeline-status to include
# project name, current task ID, and execution phase.
#
# Environment variables (optional overrides):
#   TELEGRAM_BOT_TOKEN — Bot API token
#   TELEGRAM_CHAT_ID   — Target chat ID

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  exit 0
fi

# Extract project name from cwd
PROJECT=""
if [ -n "$CWD" ]; then
  PROJECT=$(basename "$CWD")
fi

# Read pipeline status if exists
STATUS_FILE=""
if [ -n "$CWD" ] && [ -f "$CWD/.tasks/.pipeline-status" ]; then
  STATUS_FILE="$CWD/.tasks/.pipeline-status"
elif [ -n "$CLAUDE_PROJECT_DIR" ] && [ -f "$CLAUDE_PROJECT_DIR/.tasks/.pipeline-status" ]; then
  STATUS_FILE="$CLAUDE_PROJECT_DIR/.tasks/.pipeline-status"
fi

TASK_ID=""
TASK_DESC=""
PHASE=""
REQUEST=""
if [ -n "$STATUS_FILE" ]; then
  TASK_ID=$(grep '^CURRENT_TASK=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2-)
  TASK_DESC=$(grep '^CURRENT_DESC=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2-)
  PHASE=$(grep '^PHASE=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2-)
  REQUEST=$(grep '^REQUEST=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2-)
fi

# Build context line
CONTEXT=""
if [ -n "$TASK_ID" ] && [ -n "$TASK_DESC" ]; then
  CONTEXT="${TASK_ID} | ${TASK_DESC}"
elif [ -n "$TASK_ID" ]; then
  CONTEXT="${TASK_ID}"
fi

case "$EVENT" in
  "Notification")
    TEXT="🔔 *${PROJECT}*"
    [ -n "$CONTEXT" ] && TEXT="${TEXT}
📋 ${CONTEXT}"
    TEXT="${TEXT}
${MESSAGE}"
    ;;

  "Stop")
    TEXT="✅ *${PROJECT}* — Задача завершена"
    [ -n "$REQUEST" ] && TEXT="${TEXT}
📝 ${REQUEST}"
    [ -n "$CONTEXT" ] && TEXT="${TEXT}
📋 ${CONTEXT}"
    ;;

  "SubagentStop")
    AGENT=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
    TEXT="🤖 *${PROJECT}*"
    [ -n "$PHASE" ] && TEXT="${TEXT} | ${PHASE}"
    TEXT="${TEXT}
Агент *${AGENT}* завершил работу"
    [ -n "$CONTEXT" ] && TEXT="${TEXT}
📋 ${CONTEXT}"
    ;;

  *)
    TEXT="ℹ️ *${PROJECT}*: ${EVENT}"
    ;;
esac

curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="${TEXT}" \
  -d parse_mode="Markdown" > /dev/null 2>&1

exit 0
