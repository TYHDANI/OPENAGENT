#!/usr/bin/env bash
# OPENAGENT — 12_growth agent launcher
# Analyzes post-launch metrics and generates growth optimization plan.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "growth")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[12_growth] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read launch report if available ──────────────────────────────
LAUNCH_CONTEXT=""
for launch_file in "$PROJECT_DIR/launch/"*.json "$PROJECT_DIR/launch/"*.md; do
  if [ -f "$launch_file" ]; then
    LAUNCH_CONTEXT="${LAUNCH_CONTEXT}
===FILE: $(basename "$launch_file")===
$(head -80 "$launch_file" 2>/dev/null)
===ENDFILE===
"
  fi
done

# ── Read App Store description for ASO analysis ──────────────────
ASO_CONTEXT=""
if [ -f "$PROJECT_DIR/promo/app_store_description.md" ]; then
  ASO_CONTEXT="$(cat "$PROJECT_DIR/promo/app_store_description.md")"
fi

# ── Build the growth prompt ──────────────────────────────────────
GROWTH_PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== LAUNCH MATERIALS ===
${LAUNCH_CONTEXT:-No launch data found.}

=== CURRENT APP STORE DESCRIPTION ===
${ASO_CONTEXT:-No App Store description found.}

=== INSTRUCTIONS ===
You are the Growth agent for OPENAGENT. Analyze the app and generate optimization recommendations:

1. ASO OPTIMIZATION
   - Analyze current App Store title, subtitle, keywords
   - Suggest keyword improvements based on category competition
   - Recommend description changes for better conversion
   - Save to: ${PROJECT_DIR}/growth/aso_recommendations.json

2. REVIEW RESPONSE TEMPLATES
   - Generate 5 review response templates (1-star through 5-star)
   - Professional, empathetic, action-oriented
   - Save to: ${PROJECT_DIR}/growth/review_templates.json

3. FEATURE PRIORITY
   - Based on app category and competition, suggest top 3 features for next update
   - Include effort estimate (low/medium/high) and expected impact
   - Save to: ${PROJECT_DIR}/growth/feature_roadmap.json

4. GROWTH PLAN
   - Week 1-4 growth tactics (organic + paid)
   - Content calendar (2 posts/week per platform)
   - A/B test recommendations for screenshots and description
   - Save to: ${PROJECT_DIR}/growth/growth_plan.json

5. UPDATE STATE
   Update ${STATE_FILE} with:
   - "growth_plan_generated": true
   - "status": "shipped"
   - "phase_name": "shipped"

Create output directory: mkdir -p ${PROJECT_DIR}/growth/

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute Growth Agent ─────────────────────────────────────────
echo "[12_growth] Generating growth plan for: $(basename "$PROJECT_DIR")"
echo "[12_growth] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

mkdir -p "$PROJECT_DIR/growth"

GROWTH_BACKEND=$(get_backend "$MODEL")

if [ "$GROWTH_BACKEND" = "qwen" ]; then
  echo "[12_growth] Running via Qwen..."
  if GROWTH_OUTPUT=$(qwen_call "$GROWTH_PROMPT" "$MODEL" 2>/dev/null); then
    echo "$GROWTH_OUTPUT" > "$PROJECT_DIR/growth/growth_plan_raw.md"
    python3 -c "
import json
from datetime import datetime, timezone
with open('$STATE_FILE', 'r') as f:
    state = json.load(f)
state['growth_plan_generated'] = True
state['status'] = 'shipped'
state['phase_name'] = 'shipped'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
    echo "[12_growth] Growth plan generated (Qwen). App shipped."
    exit 0
  else
    echo "[12_growth] ERROR: Growth agent failed (Qwen)."
    exit 1
  fi
else
  if echo "$GROWTH_PROMPT" | claude --print --dangerously-skip-permissions --model "$MODEL" 2>/dev/null; then
    echo "[12_growth] Growth plan generated. App shipped."
    exit 0
  else
    echo "[12_growth] ERROR: Growth agent failed."
    exit 1
  fi
fi
