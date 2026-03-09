#!/usr/bin/env bash
# OPENAGENT — One-Time App Store Signing Setup
# Interactive setup wizard for App Store Connect credentials
#
# Usage: bash orchestrator/setup_signing.sh

set -euo pipefail

echo "═══════════════════════════════════════════════"
echo "  OPENAGENT — App Store Signing Setup"
echo "═══════════════════════════════════════════════"
echo ""

ENV_FILE="$HOME/.env.openagent"

# ── Check existing config ─────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  existing_team=$(grep "^TEAM_ID=" "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")
  existing_key=$(grep "^ASC_KEY_ID=" "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")
  existing_issuer=$(grep "^ASC_ISSUER_ID=" "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")

  if [ -n "$existing_team" ] && [ -n "$existing_key" ] && [ -n "$existing_issuer" ]; then
    echo "Existing configuration found:"
    echo "  Team ID:    $existing_team"
    echo "  Key ID:     $existing_key"
    echo "  Issuer ID:  $existing_issuer"
    echo ""
    read -p "Reconfigure? (y/N): " reconfigure
    if [[ ! "$reconfigure" =~ ^[Yy] ]]; then
      echo "Keeping existing configuration."
      exit 0
    fi
  fi
fi

echo "You'll need 3 things from Apple:"
echo ""
echo "  1. TEAM ID"
echo "     → https://developer.apple.com/account → Membership Details"
echo "     → Format: XXXXXXXXXX (10 characters)"
echo ""
echo "  2. APP STORE CONNECT API KEY"
echo "     → https://appstoreconnect.apple.com/access/integrations/api"
echo "     → Click '+' to generate a new key"
echo "     → Role: Admin or App Manager"
echo "     → Downloads a .p8 file (AuthKey_XXXXXX.p8)"
echo ""
echo "  3. KEY ID + ISSUER ID"
echo "     → Shown on the same API Keys page after generating"
echo ""
echo "═══════════════════════════════════════════════"
echo ""

# ── Collect credentials ───────────────────────────────────────────
read -p "Team ID (10 chars): " TEAM_ID
if [ ${#TEAM_ID} -ne 10 ]; then
  echo "WARNING: Team ID is usually 10 characters. You entered ${#TEAM_ID}."
  read -p "Continue anyway? (y/N): " cont
  [[ "$cont" =~ ^[Yy] ]] || exit 1
fi

read -p "API Key ID: " ASC_KEY_ID
read -p "Issuer ID: " ASC_ISSUER_ID

echo ""
echo "Now place the .p8 key file:"
echo "  Option A: Drag the .p8 file here and press Enter"
echo "  Option B: Just press Enter if you'll copy it manually to ~/.appstore/"
echo ""
read -p ".p8 file path (or Enter to skip): " P8_PATH

mkdir -p "$HOME/.appstore"

if [ -n "$P8_PATH" ]; then
  # Clean up path (remove quotes, trailing spaces)
  P8_PATH=$(echo "$P8_PATH" | sed "s/^['\"]//;s/['\"]$//;s/ *$//")

  if [ -f "$P8_PATH" ]; then
    cp "$P8_PATH" "$HOME/.appstore/"
    chmod 600 "$HOME/.appstore/"*.p8
    echo "Key file copied to ~/.appstore/"
  else
    echo "WARNING: File not found: $P8_PATH"
    echo "Please copy your AuthKey_*.p8 file to ~/.appstore/ manually"
  fi
else
  echo "Please copy your AuthKey_*.p8 file to ~/.appstore/"
fi

# ── Save to .env.openagent ────────────────────────────────────────
# Remove old entries if they exist
if [ -f "$ENV_FILE" ]; then
  sed -i '' '/^TEAM_ID=/d' "$ENV_FILE" 2>/dev/null || true
  sed -i '' '/^ASC_KEY_ID=/d' "$ENV_FILE" 2>/dev/null || true
  sed -i '' '/^ASC_ISSUER_ID=/d' "$ENV_FILE" 2>/dev/null || true
fi

cat >> "$ENV_FILE" << EOF

# App Store Connect (added $(date +%Y-%m-%d))
TEAM_ID=$TEAM_ID
ASC_KEY_ID=$ASC_KEY_ID
ASC_ISSUER_ID=$ASC_ISSUER_ID
EOF

chmod 600 "$ENV_FILE"

echo ""
echo "═══════════════════════════════════════════════"
echo "  Setup complete!"
echo "═══════════════════════════════════════════════"
echo ""
echo "Saved to: $ENV_FILE"
echo "Key dir:  ~/.appstore/"
echo ""
echo "Verify with:"
echo "  bash orchestrator/appstore_submit.sh projects/YOUR_APP status"
echo ""
echo "Submit a single app:"
echo "  bash orchestrator/appstore_submit.sh projects/YOUR_APP full-submit"
echo ""
echo "Submit ALL ready apps:"
echo "  bash orchestrator/appstore_submit.sh projects/ANY_APP batch"
echo ""

# ── Verify .p8 key exists ────────────────────────────────────────
key_count=$(find "$HOME/.appstore" -name "AuthKey_*.p8" 2>/dev/null | wc -l | xargs)
if [ "$key_count" -eq 0 ]; then
  echo "⚠  WARNING: No .p8 key file found in ~/.appstore/"
  echo "   Download from App Store Connect and copy to ~/.appstore/"
  echo "   Without this file, submissions will fail."
else
  echo "AuthKey file found in ~/.appstore/ — ready to submit!"
fi

# ── Install PyJWT if needed (for App Store Connect API) ──────────
if ! python3 -c "import jwt" 2>/dev/null; then
  echo ""
  echo "Installing PyJWT (required for App Store Connect API)..."
  pip3 install PyJWT cryptography 2>/dev/null || {
    echo "WARNING: Could not install PyJWT. Install manually:"
    echo "  pip3 install PyJWT cryptography"
  }
fi
