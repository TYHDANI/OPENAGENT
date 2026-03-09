#!/usr/bin/env bash
# OPENAGENT — 11_launch agent launcher
# Generates launch materials and queues social media posts.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "launch")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[11_launch] ERROR: Project directory not found: $PROJECT_DIR"
  exit 1
fi

# ── Read agent instructions ─────────────────────────────────────
AGENT_PROMPT=""
if [ -f "$AGENT_MD" ]; then
  AGENT_PROMPT="$(cat "$AGENT_MD")"
fi

# ── Read project state and promo materials ───────────────────────
STATE_CONTEXT=""
if [ -f "$STATE_FILE" ]; then
  STATE_CONTEXT="$(cat "$STATE_FILE")"
fi

PROMO_CONTEXT=""
for promo_file in "$PROJECT_DIR/promo/"*.md "$PROJECT_DIR/promo/"*.json; do
  if [ -f "$promo_file" ]; then
    PROMO_CONTEXT="${PROMO_CONTEXT}
===FILE: $(basename "$promo_file")===
$(head -100 "$promo_file" 2>/dev/null)
===ENDFILE===
"
  fi
done

VIDEO_CONTEXT=""
for video_file in "$PROJECT_DIR/promo/videos/"*.json; do
  if [ -f "$video_file" ]; then
    VIDEO_CONTEXT="${VIDEO_CONTEXT}
===FILE: $(basename "$video_file")===
$(head -80 "$video_file" 2>/dev/null)
===ENDFILE===
"
  fi
done

# ── Source auto_publish if available ─────────────────────────────
if [ -f "$ROOT_DIR/orchestrator/auto_publish.sh" ]; then
  source "$ROOT_DIR/orchestrator/auto_publish.sh"
fi

# ── Build the launch prompt ──────────────────────────────────────
LAUNCH_PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== PROMO MATERIALS ===
${PROMO_CONTEXT:-No promo materials found. Generate them first.}

=== VIDEO AD SPECS ===
${VIDEO_CONTEXT:-No video ad specs found.}

=== INSTRUCTIONS ===
You are the Launch agent for OPENAGENT. Your job is to prepare and execute the launch:

1. LAUNCH CHECKLIST
   - Verify all promo materials exist (app_store_description.md, social_posts.json)
   - Verify screenshots exist in promo/screenshots/
   - Verify video ad specs exist in promo/videos/
   - Check that App Store metadata is complete

2. SOCIAL MEDIA QUEUE
   Generate launch posts for each platform and save to ${PROJECT_DIR}/launch/post_queue.json:
   - Twitter/X: 3 tweets (launch day, day 2, day 7)
   - Reddit: 2 posts (relevant subreddit + r/iosapps)
   - Product Hunt: title + tagline + description
   - LinkedIn: 1 professional announcement

3. PRESS OUTREACH
   Generate email templates at ${PROJECT_DIR}/launch/press_emails.json:
   - 3 personalized email templates for tech journalists
   - 2 templates for relevant niche influencers

4. LAUNCH TIMELINE
   Create ${PROJECT_DIR}/launch/timeline.json with:
   - Day -7: Teaser posts
   - Day -1: Press embargo lift
   - Day 0: Launch (all channels)
   - Day +1: Thank you + early reviews
   - Day +7: Week 1 recap

5. UPDATE STATE
   Update ${STATE_FILE} with:
   - "launch_ready": true
   - "launch_channels": ["twitter", "reddit", "producthunt", "linkedin"]
   - "status": "complete"

Create output directory: mkdir -p ${PROJECT_DIR}/launch/

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute Launch Agent ─────────────────────────────────────────
echo "[11_launch] Preparing launch for: $(basename "$PROJECT_DIR")"
echo "[11_launch] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

mkdir -p "$PROJECT_DIR/launch"

LAUNCH_BACKEND=$(get_backend "$MODEL")

if [ "$LAUNCH_BACKEND" = "qwen" ]; then
  echo "[11_launch] Running via Qwen..."
  if LAUNCH_OUTPUT=$(qwen_call "$LAUNCH_PROMPT" "$MODEL" 2>/dev/null); then
    echo "$LAUNCH_OUTPUT" > "$PROJECT_DIR/launch/launch_plan.md"
    python3 -c "
import json
from datetime import datetime, timezone
with open('$STATE_FILE', 'r') as f:
    state = json.load(f)
state['launch_ready'] = True
state['launch_channels'] = ['twitter', 'reddit', 'producthunt', 'linkedin']
state['status'] = 'complete'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
    echo "[11_launch] Launch plan generated (Qwen). Ready for growth."
    exit 0
  else
    echo "[11_launch] ERROR: Launch agent failed (Qwen)."
    exit 1
  fi
else
  if claude --print --dangerously-skip-permissions --model "$MODEL" "$LAUNCH_PROMPT" < /dev/null; then
    echo "[11_launch] Launch plan generated. Ready for growth."
    exit 0
  else
    echo "[11_launch] ERROR: Launch agent failed."
    exit 1
  fi
fi
