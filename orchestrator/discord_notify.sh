#!/usr/bin/env bash
# OPENAGENT — Discord Notification Helper (v2 — Rich Embeds)
# Sends pipeline events to Discord via Bot Token REST API
# Usage: discord_notify "message" [color] [title]
#   color: "green" (success), "red" (failure), "yellow" (warning), "blue" (info)
#   title: embed title (optional)

set -euo pipefail

MESSAGE="${1:?Usage: discord_notify \"message\" [color] [title]}"
COLOR_NAME="${2:-blue}"
TITLE="${3:-OPENAGENT Pipeline}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load env
ENV_FILE="$HOME/.env.openagent"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
CHANNEL_CACHE="$ROOT_DIR/.discord_channel_id"

# Color mapping (Discord embed colors are decimal)
case "$COLOR_NAME" in
  green|success)  COLOR=3066993 ;;  # #2ECC71
  red|error)      COLOR=15158332 ;; # #E74C3C
  yellow|warning) COLOR=15844367 ;; # #F1C40F
  blue|info)      COLOR=3447003 ;;  # #3498DB
  amber)          COLOR=16098851 ;; # #F5A623
  *)              COLOR=3447003 ;;
esac

# ── Try webhook first (fastest) ───────────────────────────────────
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
if [ -n "$WEBHOOK_URL" ]; then
  PAYLOAD=$(python3 -c "
import json, sys
embed = {
    'title': '''$TITLE''',
    'description': '''$MESSAGE''',
    'color': $COLOR,
    'footer': {'text': 'OPENAGENT Pipeline'},
    'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
}
print(json.dumps({'embeds': [embed]}))
" 2>/dev/null)
  curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null 2>&1
  exit 0
fi

# ── Use Bot Token + REST API ──────────────────────────────────────
if [ -z "$BOT_TOKEN" ]; then
  # No token — queue to file as fallback
  NOTIFY_FILE="$ROOT_DIR/logs/discord_notifications.jsonl"
  printf '{"timestamp":"%s","message":"%s","color":"%s","title":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(echo "$MESSAGE" | sed 's/"/\\"/g')" \
    "$COLOR_NAME" "$TITLE" \
    >> "$NOTIFY_FILE"
  echo "[discord_notify] No token — queued notification"
  exit 0
fi

# Find the #openagent-status channel ID (env var > cache > API lookup)
get_channel_id() {
  # Check env var first
  if [ -n "${DISCORD_CHANNEL_ID:-}" ]; then
    echo "$DISCORD_CHANNEL_ID"
    return
  fi

  if [ -f "$CHANNEL_CACHE" ]; then
    cat "$CHANNEL_CACHE"
    return
  fi

  # Get guilds the bot is in
  local guilds
  guilds=$(curl -s -H "Authorization: Bot $BOT_TOKEN" \
    "https://discord.com/api/v10/users/@me/guilds" 2>/dev/null)

  local guild_id
  guild_id=$(echo "$guilds" | python3 -c "
import sys, json
guilds = json.load(sys.stdin)
if guilds:
    print(guilds[0]['id'])
" 2>/dev/null)

  if [ -z "$guild_id" ]; then
    echo ""
    return
  fi

  # Get channels in that guild
  local channels
  channels=$(curl -s -H "Authorization: Bot $BOT_TOKEN" \
    "https://discord.com/api/v10/guilds/$guild_id/channels" 2>/dev/null)

  local channel_id
  channel_id=$(echo "$channels" | python3 -c "
import sys, json
channels = json.load(sys.stdin)
for ch in channels:
    if ch.get('name') == 'openagent-status':
        print(ch['id'])
        break
else:
    # Fall back to first text channel
    for ch in channels:
        if ch.get('type') == 0:
            print(ch['id'])
            break
" 2>/dev/null)

  if [ -n "$channel_id" ]; then
    echo "$channel_id" > "$CHANNEL_CACHE"
    echo "$channel_id"
  fi
}

CHANNEL_ID=$(get_channel_id)

if [ -z "$CHANNEL_ID" ]; then
  echo "[discord_notify] Could not find channel. Queuing notification."
  NOTIFY_FILE="$ROOT_DIR/logs/discord_notifications.jsonl"
  printf '{"timestamp":"%s","message":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(echo "$MESSAGE" | sed 's/"/\\"/g')" \
    >> "$NOTIFY_FILE"
  exit 0
fi

# Build embed payload
PAYLOAD=$(python3 -c "
import json
embed = {
    'title': '''$TITLE''',
    'description': '''$MESSAGE''',
    'color': $COLOR,
    'footer': {'text': 'OPENAGENT Pipeline | $(date -u +%H:%M) UTC'}
}
print(json.dumps({'embeds': [embed]}))
" 2>/dev/null)

# Send via Discord REST API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://discord.com/api/v10/channels/$CHANNEL_ID/messages" \
  -H "Authorization: Bot $BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "[discord_notify] Sent to #openagent-status"
else
  echo "[discord_notify] Failed (HTTP $HTTP_CODE). Queuing."
  NOTIFY_FILE="$ROOT_DIR/logs/discord_notifications.jsonl"
  printf '{"timestamp":"%s","message":"%s","http_code":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(echo "$MESSAGE" | sed 's/"/\\"/g')" \
    "$HTTP_CODE" \
    >> "$NOTIFY_FILE"
fi
