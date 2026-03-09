#!/usr/bin/env bash
# OPENAGENT — 07_onboarding agent launcher
# Creates and integrates an onboarding flow into the app.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
MODEL=$(get_model "onboarding" "standard" "$PROJECT_NAME")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
TEMPLATES_DIR="$AGENT_DIR/templates"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[07_onboarding] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read onboarding templates if any ────────────────────────────
ONBOARDING_TEMPLATES=""
if [ -d "$TEMPLATES_DIR" ]; then
  for f in "$TEMPLATES_DIR"/*; do
    [ -f "$f" ] || continue
    ONBOARDING_TEMPLATES="${ONBOARDING_TEMPLATES}
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

=== ONE-PAGER ===
${ONE_PAGER:-No one_pager.md found.}

=== ONBOARDING TEMPLATES ===
${ONBOARDING_TEMPLATES:-No onboarding templates found.}

=== EXISTING SWIFT FILES ===
${SOURCE_LISTING:-No Swift source files found.}

=== INSTRUCTIONS ===
You are the Onboarding agent for OPENAGENT. Your job:
1. Design and implement a polished onboarding flow for the app.
2. Create ${PROJECT_DIR}/Sources/Views/Onboarding/OnboardingView.swift with:
   - 3-5 onboarding screens using TabView with PageTabViewStyle
   - Each screen: illustration area, headline, description, progress indicator
   - Smooth animations and transitions between screens
   - "Skip" button and "Get Started" / "Continue" buttons
   - Final screen should lead to the main app or paywall
3. Create ${PROJECT_DIR}/Sources/ViewModels/OnboardingViewModel.swift to manage:
   - Current page tracking
   - UserDefaults flag for hasSeenOnboarding
   - Navigation logic (skip, next, complete)
4. Create individual page content models if needed.
5. Integrate the onboarding into the app's entry point:
   - Show onboarding on first launch only
   - After completion, go to main app view
   - Store completion state in UserDefaults
6. The onboarding content should match the app's purpose from the one-pager:
   - Highlight key features
   - Show value proposition
   - Build excitement before main app
7. Use SF Symbols for illustrations where possible (no external assets needed).
8. Update state.json at: ${STATE_FILE} with onboarding_integrated: true.

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute Claude ──────────────────────────────────────────────
echo "[07_onboarding] Starting onboarding agent for: $(basename "$PROJECT_DIR")"
echo "[07_onboarding] Model: $MODEL ($(model_tier "$MODEL"))"

if claude --print --dangerously-skip-permissions --model "$MODEL" "$PROMPT" < /dev/null; then
  echo "[07_onboarding] Onboarding phase completed successfully."
  exit 0
else
  echo "[07_onboarding] ERROR: Onboarding agent failed."
  exit 1
fi
