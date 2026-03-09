#!/bin/bash
# OPENAGENT — Sync Claude Credentials from Mac to VPS
# Usage: bash ~/OPENAGENT/orchestrator/sync_credentials.sh
#
# Extracts OAuth token from macOS Keychain and pushes to VPS.
# Run this whenever VPS agents stop working due to expired auth.

set -euo pipefail

VPS="deploy@46.225.233.219"

echo "[sync_credentials] Extracting Claude credentials from macOS Keychain..."
CREDS=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null)

if [ -z "$CREDS" ]; then
    echo "[sync_credentials] ERROR: No Claude credentials found in Keychain."
    echo "  Run 'claude auth login' locally first."
    exit 1
fi

echo "[sync_credentials] Credentials found. Pushing to VPS..."
echo "$CREDS" | ssh "$VPS" 'cat > ~/.claude/.credentials.json && chmod 600 ~/.claude/.credentials.json'

echo "[sync_credentials] Verifying on VPS..."
ssh "$VPS" 'claude auth status 2>&1'

echo "[sync_credentials] Done! VPS agents will use fresh credentials on next cycle."
