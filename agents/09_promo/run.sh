#!/usr/bin/env bash
# OPENAGENT — 09_promo agent launcher
# Generates promotional materials for app marketing.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "promo")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[09_promo] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read App Store metadata ─────────────────────────────────────
APPSTORE_METADATA=""
if [ -f "$PROJECT_DIR/appstore_metadata.json" ]; then
  APPSTORE_METADATA="$(cat "$PROJECT_DIR/appstore_metadata.json")"
fi

# ── Read icon prompt ────────────────────────────────────────────
ICON_PROMPT=""
if [ -f "$PROJECT_DIR/icon_prompt.txt" ]; then
  ICON_PROMPT="$(cat "$PROJECT_DIR/icon_prompt.txt")"
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== ONE-PAGER ===
${ONE_PAGER:-No one_pager.md found.}

=== APP STORE METADATA ===
${APPSTORE_METADATA:-No App Store metadata found.}

=== ICON PROMPT ===
${ICON_PROMPT:-No icon prompt found.}

=== INSTRUCTIONS ===
You are the Promo agent for OPENAGENT. Your job:
1. Generate a complete promotional package saved to ${PROJECT_DIR}/promo/:

2. Social Media Posts (${PROJECT_DIR}/promo/social_posts.md):
   - 5 Twitter/X posts (max 280 chars each, with hashtags)
   - 3 LinkedIn posts (professional tone, 150-300 words each)
   - 3 Instagram captions (with emoji, hashtags, call to action)
   - 1 Reddit post (authentic tone, value-first, not salesy)
   - 1 Product Hunt launch description

3. Press Kit (${PROJECT_DIR}/promo/press_kit.md):
   - Boilerplate paragraph (company/app description)
   - Key facts and figures
   - Founder quote (template)
   - Contact information template

4. Email Templates (${PROJECT_DIR}/promo/email_templates.md):
   - Launch announcement email
   - Press outreach email
   - Influencer outreach email
   - User testimonial request email

5. Landing Page Copy (${PROJECT_DIR}/promo/landing_page.md):
   - Hero section (headline + subheadline)
   - Feature sections (3-5 features with descriptions)
   - Social proof section (placeholder for testimonials)
   - Pricing section
   - FAQ (5-8 common questions)
   - CTA sections

6. ASO (App Store Optimization) recommendations (${PROJECT_DIR}/promo/aso_recommendations.md):
   - Keyword analysis and suggestions
   - Competitor keyword gaps
   - A/B test suggestions for title/subtitle
   - Review solicitation strategy

7. Launch Timeline (${PROJECT_DIR}/promo/launch_timeline.md):
   - Pre-launch checklist (7 days before)
   - Launch day activities
   - Post-launch follow-up (7 days after)

8. Update state.json at: ${STATE_FILE} with promo_materials_generated: true.

OUTPUT FORMAT: Wrap EACH output file in markers like this:
===FILE: promo/social_posts.md===
[content]
===ENDFILE===

Files to produce (use these exact paths):
- promo/social_posts.md
- promo/press_kit.md
- promo/email_templates.md
- promo/landing_page.md
- promo/aso_recommendations.md
- promo/launch_timeline.md

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute agent (Qwen or Claude) ────────────────────────────────
echo "[09_promo] Starting promo agent for: $(basename "$PROJECT_DIR")"
echo "[09_promo] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "promo_materials_generated" "true"; then
  echo "[09_promo] Promo phase completed successfully."
  exit 0
else
  echo "[09_promo] ERROR: Promo agent failed."
  exit 1
fi
