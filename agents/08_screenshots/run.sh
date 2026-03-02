#!/usr/bin/env bash
# OPENAGENT — 08_screenshots agent launcher
# Runs simulator and captures App Store screenshots.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "screenshots")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[08_screenshots] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read screenshots plan if exists ─────────────────────────────
SCREENSHOTS_PLAN=""
if [ -f "$PROJECT_DIR/appstore_screenshots_plan.md" ]; then
  SCREENSHOTS_PLAN="$(cat "$PROJECT_DIR/appstore_screenshots_plan.md")"
fi

# ── Read App Store metadata ─────────────────────────────────────
APPSTORE_METADATA=""
if [ -f "$PROJECT_DIR/appstore_metadata.json" ]; then
  APPSTORE_METADATA="$(cat "$PROJECT_DIR/appstore_metadata.json")"
fi

# ── List existing source files ──────────────────────────────────
SOURCE_LISTING=""
if [ -d "$PROJECT_DIR/Sources" ]; then
  SOURCE_LISTING="$(find "$PROJECT_DIR/Sources" -name '*.swift' -type f 2>/dev/null | sort)"
fi

# ── Detect available simulators ─────────────────────────────────
AVAILABLE_SIMULATORS=""
if command -v xcrun &>/dev/null; then
  AVAILABLE_SIMULATORS="$(xcrun simctl list devices available 2>/dev/null | head -30 || echo "Could not list simulators")"
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== ONE-PAGER ===
${ONE_PAGER:-No one_pager.md found.}

=== SCREENSHOTS PLAN ===
${SCREENSHOTS_PLAN:-No screenshots plan found — create one based on the app features.}

=== APP STORE METADATA ===
${APPSTORE_METADATA:-No App Store metadata found.}

=== EXISTING SWIFT FILES ===
${SOURCE_LISTING:-No Swift source files found.}

=== AVAILABLE SIMULATORS ===
${AVAILABLE_SIMULATORS:-No simulators detected. xcrun may not be available.}

=== INSTRUCTIONS ===
You are the Screenshots agent for OPENAGENT. Your job:
1. Create a screenshot automation script at ${PROJECT_DIR}/capture_screenshots.sh that:
   - Builds the project with xcodebuild
   - Boots required iOS simulators (iPhone 15 Pro, iPhone 15 Pro Max, iPad Pro)
   - Launches the app on each simulator
   - Uses xcrun simctl to capture screenshots at key screens
   - Saves screenshots to ${PROJECT_DIR}/screenshots/ organized by device
2. Create a UI test file for automated screenshot capture if possible:
   - ${PROJECT_DIR}/Tests/ScreenshotTests.swift
   - Navigate to each key screen and capture
3. Required App Store screenshot sizes:
   - 6.7" (iPhone 15 Pro Max): 1290 x 2796
   - 6.1" (iPhone 15 Pro): 1179 x 2556
   - 12.9" iPad Pro: 2048 x 2732
4. Capture at least 5 screenshots per device showing:
   - Onboarding highlight screen
   - Main app screen (hero shot)
   - Key feature 1
   - Key feature 2
   - Settings or paywall screen
5. Create ${PROJECT_DIR}/screenshots/README.md listing all screenshots and what they show.
6. If the project cannot be built (missing Xcode project), create a detailed script
   that can be run manually, and document the steps.
7. Update state.json at: ${STATE_FILE} with screenshots_captured: true.

OUTPUT FORMAT: Wrap EACH output file in markers like this:
===FILE: capture_screenshots.sh===
[script content]
===ENDFILE===

Files to produce:
- capture_screenshots.sh
- screenshots/README.md

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute agent (Qwen or Claude) ────────────────────────────────
echo "[08_screenshots] Starting screenshots agent for: $(basename "$PROJECT_DIR")"
echo "[08_screenshots] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "screenshots_captured" "true"; then
  echo "[08_screenshots] Screenshots phase completed successfully."
  exit 0
else
  echo "[08_screenshots] ERROR: Screenshots agent failed."
  exit 1
fi
