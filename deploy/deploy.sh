#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# OPENAGENT — Deploy to Hetzner VPS from Mac
# Run from your Mac: bash deploy/deploy.sh
#
# This script:
#   1. Copies setup_server.sh to the VPS
#   2. Copies your local .env secrets to the VPS
#   3. Runs the setup script remotely
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

SERVER="46.225.233.219"
USER="root"
SSH_KEY="$HOME/.ssh/id_ed25519"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "═══════════════════════════════════════════════════════════════"
echo " OPENAGENT — Deploying to Hetzner VPS ($SERVER)"
echo "═══════════════════════════════════════════════════════════════"

# Test SSH connection
echo "[1/4] Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$USER@$SERVER" "echo OK" 2>/dev/null; then
  echo "ERROR: Cannot SSH to $SERVER"
  echo "Make sure your SSH key is authorized on the server."
  echo ""
  echo "To add your key:"
  echo "  ssh-copy-id -i $SSH_KEY $USER@$SERVER"
  exit 1
fi
echo "SSH connection OK"

# Upload setup script
echo "[2/4] Uploading setup script..."
scp -i "$SSH_KEY" "$SCRIPT_DIR/setup_server.sh" "$USER@$SERVER:/root/setup_server.sh"

# Upload env file with secrets from local machine
echo "[3/4] Preparing environment variables..."

# Collect secrets from local environment / .zshrc
ENV_TEMP=$(mktemp)
cat > "$ENV_TEMP" << ENVEOF
# Auto-generated from local Mac environment
# $(date -u +%Y-%m-%dT%H:%M:%SZ)

ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-YOUR_KEY_HERE}
BRAVE_API_KEY_1=${BRAVE_API_KEY_1:-YOUR_KEY_HERE}
BRAVE_API_KEY_2=${BRAVE_API_KEY_2:-YOUR_KEY_HERE}
DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY:-YOUR_KEY_HERE}
ALPACA_API_KEY=${ALPACA_API_KEY:-YOUR_KEY_HERE}
ALPACA_SECRET_KEY=${ALPACA_SECRET_KEY:-YOUR_KEY_HERE}
ALPACA_BASE_URL=${ALPACA_BASE_URL:-https://paper-api.alpaca.markets}
POLYGON_API_KEY=${POLYGON_API_KEY:-YOUR_KEY_HERE}
COINGECKO_API_KEY=${COINGECKO_API_KEY:-YOUR_KEY_HERE}
APIFY_API_KEY=${APIFY_API_KEY:-YOUR_KEY_HERE}
OPENAI_API_KEY=${OPENAI_API_KEY:-YOUR_KEY_HERE}
ENVEOF

scp -i "$SSH_KEY" "$ENV_TEMP" "$USER@$SERVER:/root/.env.upload"
rm -f "$ENV_TEMP"

# Run setup
echo "[4/4] Running setup on server (this takes a few minutes)..."
ssh -i "$SSH_KEY" "$USER@$SERVER" "bash /root/setup_server.sh && cp /root/.env.upload /home/deploy/.env.openagent && chown deploy:deploy /home/deploy/.env.openagent && chmod 600 /home/deploy/.env.openagent"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " DEPLOYMENT COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Dashboard: http://$SERVER:8420"
echo "Fortress:  http://$SERVER:8080"
echo ""
echo "SSH: ssh -i $SSH_KEY deploy@$SERVER"
echo ""
