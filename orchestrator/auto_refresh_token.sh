#!/usr/bin/env bash
# OPENAGENT — Auto OAuth Token Refresh
# Runs on Mac via launchd every 2 hours.
# Extracts fresh token from macOS Keychain and pushes to VPS.

set -euo pipefail

LOG="/tmp/openagent_token_refresh.log"
VPS="deploy@46.225.233.219"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"
}

log "Starting token refresh..."

# 1. Extract credentials from macOS Keychain
CRED_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
if [ -z "$CRED_JSON" ]; then
  log "ERROR: No credentials found in Keychain"
  exit 1
fi

# 2. Extract token and expiry
TOKEN=$(echo "$CRED_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null)
EXPIRY=$(echo "$CRED_JSON" | python3 -c "import json,sys,datetime; ts=json.load(sys.stdin)['claudeAiOauth']['expiresAt']/1000; print(datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).isoformat())" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  log "ERROR: Could not extract token from Keychain"
  exit 1
fi

log "Token extracted (expires: $EXPIRY)"

# 3. Check if token has changed on VPS
VPS_TOKEN=$(ssh -o ConnectTimeout=10 "$VPS" 'grep CLAUDE_CODE_OAUTH_TOKEN ~/.env.openagent 2>/dev/null | cut -d= -f2' 2>/dev/null || echo "")

if [ "$TOKEN" = "$VPS_TOKEN" ]; then
  log "Token unchanged — skipping push"
  exit 0
fi

# 4. Push full credentials.json to VPS (includes refresh token)
echo "$CRED_JSON" | ssh -o ConnectTimeout=10 "$VPS" 'cat > ~/.claude/.credentials.json' 2>/dev/null
log "Pushed credentials.json to VPS"

# 5. Update .env.openagent on VPS
ssh -o ConnectTimeout=10 "$VPS" "sed -i 's|^CLAUDE_CODE_OAUTH_TOKEN=.*|CLAUDE_CODE_OAUTH_TOKEN=$TOKEN|' ~/.env.openagent" 2>/dev/null
log "Updated .env.openagent on VPS"

# 6. Verify
VERIFY=$(ssh -o ConnectTimeout=10 "$VPS" 'source ~/.env.openagent && claude auth status 2>&1 | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"loggedIn\",False))"' 2>/dev/null || echo "false")

if [ "$VERIFY" = "True" ]; then
  log "SUCCESS: Token refreshed and verified on VPS"
else
  log "WARNING: Token pushed but verification failed"
fi
