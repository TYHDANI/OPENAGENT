#!/usr/bin/env bash
# OPENAGENT — 03_build agent launcher
# Scaffolds the Swift project from template and writes the app code.
# Runs a review pass with Sonnet after the build phase.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
BUILD_MODEL=$(get_model "build" "standard" "$PROJECT_NAME")
REVIEW_MODEL=$(get_model "build_review" "standard" "$PROJECT_NAME")
DERIVED_DATA="/Volumes/T7/DerivedData"
BUILD_OUTPUT="/Volumes/T7/OPENAGENT_builds"
export DERIVED_DATA BUILD_OUTPUT
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
TEMPLATE_DIR="$AGENT_DIR/swift_template"
REVIEW_PROMPT_FILE="$AGENT_DIR/review_prompt.md"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[03_build] ERROR: Project directory not found: $PROJECT_DIR"
  exit 1
fi

# ── Copy Swift template if not already scaffolded ────────────────
if [ ! -f "$PROJECT_DIR/Package.swift" ] && [ ! -d "$PROJECT_DIR/Sources" ]; then
  echo "[03_build] Scaffolding project from swift_template..."
  if [ -d "$TEMPLATE_DIR" ]; then
    cp -rn "$TEMPLATE_DIR"/* "$PROJECT_DIR"/ 2>/dev/null || cp -r "$TEMPLATE_DIR"/* "$PROJECT_DIR"/
    echo "[03_build] Template copied to project directory."
  else
    echo "[03_build] WARNING: swift_template not found at $TEMPLATE_DIR"
  fi
else
  echo "[03_build] Project already scaffolded, skipping template copy."
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

# ── Read one-pager from validation ──────────────────────────────
ONE_PAGER=""
if [ -f "$PROJECT_DIR/one_pager.md" ]; then
  ONE_PAGER="$(cat "$PROJECT_DIR/one_pager.md")"
fi

# ── Read existing source files listing ──────────────────────────
SOURCE_LISTING=""
if [ -d "$PROJECT_DIR/Sources" ]; then
  SOURCE_LISTING="$(find "$PROJECT_DIR/Sources" -name '*.swift' -type f 2>/dev/null | sort)"
fi

# ── Read UI/UX references ──────────────────────────────────────
REFERENCES_CONTEXT=""
REF_DIR="$ROOT_DIR/references"
for ref_source in "$REF_DIR/$PROJECT_NAME" "$REF_DIR/global"; do
  REF_FILE="$ref_source/references.jsonl"
  if [ -f "$REF_FILE" ]; then
    REF_COUNT=$(wc -l < "$REF_FILE" | xargs)
    if [ "$REF_COUNT" -gt 0 ]; then
      REFERENCES_CONTEXT="${REFERENCES_CONTEXT}
--- References from $(basename "$ref_source") ($REF_COUNT items) ---
$(tail -20 "$REF_FILE")"
    fi
  fi
done

# ── Build the prompt ────────────────────────────────────────────
BUILD_PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== ONE-PAGER (from validation phase) ===
${ONE_PAGER:-No one_pager.md found — check validation phase.}

=== UI/UX REFERENCE MATERIAL ===
${REFERENCES_CONTEXT:-No reference images or URLs submitted. Use the DesignSystem defaults.}
Use these references as UI inspiration — match the quality, polish, and design patterns shown.

=== EXISTING SWIFT FILES ===
${SOURCE_LISTING:-No Swift source files found yet.}

=== INSTRUCTIONS ===
You are the Build agent for OPENAGENT. Your job:
1. Read the one-pager to understand what app to build.
2. The Swift project template has been scaffolded in: ${PROJECT_DIR}
3. Write all necessary Swift source files to implement the app described in the one-pager.
4. Follow iOS/SwiftUI best practices: MVVM architecture, proper error handling, accessibility.
5. Use SwiftUI for all UI code. Target iOS 17+.
6. Do NOT include API keys or secrets — use environment variables or Keychain references.
7. Create well-organized files under Sources/ with logical grouping (Views/, Models/, ViewModels/, Services/).
8. Include a basic Tests/ structure with at least placeholder test cases.
9. Update the project state.json at: ${STATE_FILE}

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute Build Agent (Opus) ──────────────────────────────────
echo "[03_build] Starting build agent for: $(basename "$PROJECT_DIR")"
echo "[03_build] Build model: $BUILD_MODEL ($(model_tier "$BUILD_MODEL"))"

if ! echo "$BUILD_PROMPT" | claude --print --dangerously-skip-permissions --model "$BUILD_MODEL" 2>/dev/null; then
  echo "[03_build] ERROR: Build agent failed."
  exit 1
fi

echo "[03_build] Build phase completed. Starting review pass..."

# ── Review Pass (Sonnet) ────────────────────────────────────────
REVIEW_INSTRUCTIONS=""
if [ -f "$REVIEW_PROMPT_FILE" ]; then
  REVIEW_INSTRUCTIONS="$(cat "$REVIEW_PROMPT_FILE")"
fi

# Re-read source listing after build
SOURCE_LISTING_POST=""
if [ -d "$PROJECT_DIR/Sources" ]; then
  SOURCE_LISTING_POST="$(find "$PROJECT_DIR/Sources" -name '*.swift' -type f 2>/dev/null | sort)"
fi

REVIEW_PROMPT="$(cat <<PROMPT_EOF
${REVIEW_INSTRUCTIONS}

=== PROJECT STATE ===
$(cat "$STATE_FILE" 2>/dev/null || echo "No state file")

=== ONE-PAGER ===
${ONE_PAGER:-No one_pager.md found.}

=== SWIFT FILES PRODUCED BY BUILD AGENT ===
${SOURCE_LISTING_POST:-No Swift files found after build — this is a problem.}

=== INSTRUCTIONS ===
You are the Code Review agent for OPENAGENT. Your job:
1. Review all Swift files in ${PROJECT_DIR}/Sources/ for:
   - Compilation errors or obvious bugs
   - Missing imports or broken references
   - Security issues (hardcoded secrets, insecure storage)
   - SwiftUI best practices violations
   - Accessibility issues (missing labels, poor contrast references)
2. Fix any critical issues directly by editing the files.
3. Do NOT rewrite working code — only fix real problems.
4. Write a brief review summary to: ${PROJECT_DIR}/review_notes.md
5. Update the state.json with review_completed: true

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

REVIEW_BACKEND=$(get_backend "$REVIEW_MODEL")
echo "[03_build] Review model: $REVIEW_MODEL ($(model_tier "$REVIEW_MODEL")) | Backend: $REVIEW_BACKEND"

if [ "$REVIEW_BACKEND" = "qwen" ]; then
  if qwen_call "$REVIEW_PROMPT" "$REVIEW_MODEL" > "$PROJECT_DIR/review_notes.md" 2>/dev/null; then
    echo "[03_build] Build + review completed successfully (Qwen)."
    exit 0
  else
    echo "[03_build] WARNING: Review pass failed (Qwen), but build succeeded."
    exit 0
  fi
else
  if echo "$REVIEW_PROMPT" | claude --print --dangerously-skip-permissions --model "$REVIEW_MODEL" 2>/dev/null; then
    echo "[03_build] Build + review completed successfully."
    exit 0
  else
    echo "[03_build] WARNING: Review pass failed, but build succeeded."
    exit 0
  fi
fi
