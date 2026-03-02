#!/usr/bin/env bash
# OPENAGENT — 06_appstore_prep agent launcher
# Generates App Store listing metadata and icon prompt.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "appstore_prep")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
TEMPLATES_DIR="$AGENT_DIR/templates"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[06_appstore_prep] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read one-pager ──────────────────────────────────────────────
ONE_PAGER=""
if [ -f "$PROJECT_DIR/one_pager.md" ]; then
  ONE_PAGER="$(cat "$PROJECT_DIR/one_pager.md")"
fi

# ── Read listing templates if any ───────────────────────────────
LISTING_TEMPLATES=""
if [ -d "$TEMPLATES_DIR" ]; then
  for f in "$TEMPLATES_DIR"/*; do
    [ -f "$f" ] || continue
    LISTING_TEMPLATES="${LISTING_TEMPLATES}
--- $(basename "$f") ---
$(cat "$f")
"
  done
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== ONE-PAGER ===
${ONE_PAGER:-No one_pager.md found.}

=== LISTING TEMPLATES ===
${LISTING_TEMPLATES:-No listing templates found.}

=== INSTRUCTIONS ===
You are the App Store Prep agent for OPENAGENT. Your job:
1. Generate complete App Store listing metadata and save to ${PROJECT_DIR}/appstore_metadata.json:
   {
     "app_name": "...",
     "subtitle": "..." (max 30 chars),
     "description": "..." (up to 4000 chars, with feature bullets),
     "keywords": "..." (max 100 chars, comma-separated),
     "primary_category": "...",
     "secondary_category": "...",
     "age_rating": "4+|9+|12+|17+",
     "privacy_url": "...",
     "support_url": "...",
     "marketing_url": "...",
     "whats_new": "..." (for updates),
     "promotional_text": "..." (max 170 chars)
   }
2. Generate localized descriptions for key markets:
   - Save to ${PROJECT_DIR}/appstore_localizations.json
   - Include: en-US, es-ES, fr-FR, de-DE, ja-JP, zh-Hans
3. Generate an icon generation prompt and save to ${PROJECT_DIR}/icon_prompt.txt:
   - Describe the ideal app icon in detail for an AI image generator
   - Specify: style, colors, symbols, mood
   - Must work at 1024x1024 and remain recognizable at small sizes
   - Follow Apple HIG for app icons (no text, simple shapes, vivid colors)
4. Create ${PROJECT_DIR}/appstore_screenshots_plan.md describing what each screenshot should show.
5. Update state.json at: ${STATE_FILE} with appstore_prep_completed: true.

OUTPUT FORMAT: Wrap EACH output file in markers like this:
===FILE: appstore_metadata.json===
[JSON content]
===ENDFILE===

Files to produce (use these exact paths):
- appstore_metadata.json
- appstore_localizations.json
- icon_prompt.txt
- appstore_screenshots_plan.md

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute agent (Qwen or Claude) ────────────────────────────────
echo "[06_appstore_prep] Starting App Store prep agent for: $(basename "$PROJECT_DIR")"
echo "[06_appstore_prep] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "appstore_prep_completed" "true"; then
  echo "[06_appstore_prep] App Store prep completed successfully."
  exit 0
else
  echo "[06_appstore_prep] ERROR: App Store prep agent failed."
  exit 1
fi
