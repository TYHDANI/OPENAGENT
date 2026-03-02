#!/usr/bin/env bash
# OPENAGENT — 05_monetization agent launcher
# Integrates StoreKit configuration and PaywallView into the project.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
MODEL=$(get_model "monetization" "standard" "$PROJECT_NAME")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
STOREKIT_DIR="$AGENT_DIR/storekit"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[05_monetization] ERROR: Project directory not found: $PROJECT_DIR"
  exit 1
fi

# ── Read agent instructions ─────────────────────────────────────
AGENT_PROMPT=""
if [ -f "$AGENT_MD" ]; then
  AGENT_PROMPT="$(cat "$AGENT_MD")"
fi

# ── Read project state ──────────────────────────────────────────
STATE_CONTEXT=""
if [ -f "$STATE_FILE" ]; then
  STATE_CONTEXT="$(cat "$STATE_FILE")"
fi

# ── Read one-pager for monetization strategy ────────────────────
ONE_PAGER=""
if [ -f "$PROJECT_DIR/one_pager.md" ]; then
  ONE_PAGER="$(cat "$PROJECT_DIR/one_pager.md")"
fi

# ── Read StoreKit templates ────────────────────────────────────
STOREKIT_TEMPLATES=""
if [ -d "$STOREKIT_DIR" ]; then
  for f in "$STOREKIT_DIR"/*; do
    [ -f "$f" ] || continue
    STOREKIT_TEMPLATES="${STOREKIT_TEMPLATES}
--- $(basename "$f") ---
$(cat "$f")
"
  done
fi

# ── List existing source files ──────────────────────────────────
SOURCE_LISTING=""
if [ -d "$PROJECT_DIR/Sources" ]; then
  SOURCE_LISTING="$(find "$PROJECT_DIR/Sources" -name '*.swift' -type f 2>/dev/null | sort)"
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== ONE-PAGER (monetization strategy) ===
${ONE_PAGER:-No one_pager.md found.}

=== STOREKIT TEMPLATES ===
${STOREKIT_TEMPLATES:-No StoreKit templates found in $STOREKIT_DIR.}

=== EXISTING SWIFT FILES ===
${SOURCE_LISTING:-No Swift source files found.}

=== INSTRUCTIONS ===
You are the Monetization agent for OPENAGENT. Your job:
1. Read the one-pager to understand the monetization strategy (freemium, subscription, one-time purchase).
2. Create or update a StoreKit 2 configuration file in the project:
   - ${PROJECT_DIR}/Configuration.storekit (for Xcode StoreKit testing)
3. Create a PaywallView.swift in ${PROJECT_DIR}/Sources/Views/ that:
   - Displays subscription/purchase options using StoreKit 2 APIs
   - Has a clean, modern SwiftUI design
   - Includes restore purchases functionality
   - Shows trial period information if applicable (default: 7-day trial)
   - Handles loading, error, and success states
4. Create a StoreKitManager.swift in ${PROJECT_DIR}/Sources/Services/ that:
   - Manages product fetching with StoreKit 2
   - Handles transactions and entitlements
   - Provides an @Observable or ObservableObject interface for SwiftUI
   - Persists entitlement state
5. Wire the paywall into the app's navigation (update existing views as needed).
6. Default pricing: \$2.99/month (Apple Small Business Program, 15% commission).
7. Update state.json at: ${STATE_FILE} with monetization_integrated: true.

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute Claude ──────────────────────────────────────────────
echo "[05_monetization] Starting monetization agent for: $(basename "$PROJECT_DIR")"
echo "[05_monetization] Model: $MODEL ($(model_tier "$MODEL"))"

if claude --print --dangerously-skip-permissions --model "$MODEL" "$PROMPT" < /dev/null; then
  echo "[05_monetization] Monetization phase completed successfully."
  exit 0
else
  echo "[05_monetization] ERROR: Monetization agent failed."
  exit 1
fi
