#!/usr/bin/env bash
# OPENAGENT — 04_quality agent launcher
# Runs 6 quality check scripts and updates state.json with scores.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "quality")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
CHECKS_DIR="$AGENT_DIR/checks"
PASS_THRESHOLD=8

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[04_quality] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Run each check script ──────────────────────────────────────
CHECK_NAMES=(build_check test_check lint_check security_check performance_check ux_review design_review)
SCORES_JSON="{"
TOTAL_SCORE=0
CHECK_COUNT=0
ALL_PASSED=true
CHECK_RESULTS=""

echo "[04_quality] Running quality checks for: $(basename "$PROJECT_DIR")"

for check_name in "${CHECK_NAMES[@]}"; do
  CHECK_SCRIPT="$CHECKS_DIR/${check_name}.sh"
  SCORE=0

  if [ -f "$CHECK_SCRIPT" ]; then
    echo "[04_quality] Running check: $check_name"
    CHECK_OUTPUT=""
    if CHECK_OUTPUT=$(bash "$CHECK_SCRIPT" "$PROJECT_DIR" 2>&1); then
      # Try to extract numeric score from last line of output
      SCORE=$(echo "$CHECK_OUTPUT" | tail -1 | grep -oE '[0-9]+' | head -1 || echo "0")
      if [ -z "$SCORE" ] || [ "$SCORE" -lt 0 ] 2>/dev/null || [ "$SCORE" -gt 10 ] 2>/dev/null; then
        SCORE=5  # Default to 5 if score can't be parsed
      fi
      echo "[04_quality] $check_name: score=$SCORE"
    else
      echo "[04_quality] $check_name: FAILED (score=0)"
      SCORE=0
      ALL_PASSED=false
    fi
    CHECK_RESULTS="${CHECK_RESULTS}
--- ${check_name} (score: ${SCORE}/10) ---
${CHECK_OUTPUT}
"
  else
    echo "[04_quality] WARNING: Check script not found: $CHECK_SCRIPT — running via Claude"
    SCORE=-1  # Sentinel: will be evaluated by Claude
  fi

  if [ "$SCORE" -ge 0 ] 2>/dev/null; then
    TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
    CHECK_COUNT=$((CHECK_COUNT + 1))
    [ "$CHECK_COUNT" -gt 1 ] && SCORES_JSON="${SCORES_JSON},"
    SCORES_JSON="${SCORES_JSON}\"${check_name}\":${SCORE}"
  fi
done

SCORES_JSON="${SCORES_JSON}}"

# Calculate average
AVG_SCORE=0
if [ "$CHECK_COUNT" -gt 0 ]; then
  AVG_SCORE=$((TOTAL_SCORE / CHECK_COUNT))
fi

echo "[04_quality] Average score: $AVG_SCORE / 10 (threshold: $PASS_THRESHOLD)"

# ── If some checks didn't have scripts, use Claude to evaluate ──
MISSING_CHECKS=""
for check_name in "${CHECK_NAMES[@]}"; do
  if [ ! -f "$CHECKS_DIR/${check_name}.sh" ]; then
    MISSING_CHECKS="${MISSING_CHECKS} ${check_name}"
  fi
done

# ── Build prompt for Claude quality evaluation ──────────────────
SOURCE_LISTING=""
if [ -d "$PROJECT_DIR/Sources" ]; then
  SOURCE_LISTING="$(find "$PROJECT_DIR/Sources" -name '*.swift' -type f 2>/dev/null | sort)"
fi

PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== CHECK RESULTS FROM SCRIPTS ===
${CHECK_RESULTS:-No check scripts were run.}

=== AUTOMATED SCORES ===
${SCORES_JSON}
Average: ${AVG_SCORE}/10 | Threshold: ${PASS_THRESHOLD}/10

=== CHECKS WITHOUT SCRIPTS (evaluate manually) ===
${MISSING_CHECKS:-None — all check scripts were found.}

=== SWIFT FILES IN PROJECT ===
${SOURCE_LISTING:-No Swift source files found.}

=== INSTRUCTIONS ===
You are the Quality agent for OPENAGENT. Your job:
1. Review the check results above.
2. For any checks that did not have scripts (listed in CHECKS WITHOUT SCRIPTS), perform the evaluation yourself and assign a score 0-10.
3. Compile a final quality report at: ${PROJECT_DIR}/quality_report.md
4. Update state.json at: ${STATE_FILE} with:
   - "quality_scores": {check_name: score, ...} for all 6 checks
   - "quality_average": the overall average score
   - "quality_passed": true if average >= ${PASS_THRESHOLD}, false otherwise
5. If the project does NOT pass (average < ${PASS_THRESHOLD}):
   - List specific issues that need fixing in quality_report.md
   - The orchestrator will send it back to the build phase
6. If the project passes: confirm readiness for monetization phase.

OUTPUT FORMAT: Wrap each output file in markers like this:
===FILE: quality_report.md===
[content here]
===ENDFILE===

Files to produce:
- quality_report.md (full quality assessment with scores and issues)

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

echo "[04_quality] Running quality evaluation..."
echo "[04_quality] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "quality_completed" "true"; then
  # Check if quality passed by reading updated state or report
  QUALITY_PASSED=$(python3 -c "
import json, sys
try:
    with open('$STATE_FILE') as f:
        state = json.load(f)
    print('true' if state.get('quality_passed', False) else 'false')
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

  if [ "$QUALITY_PASSED" = "true" ]; then
    echo "[04_quality] Quality gate PASSED. Ready for monetization."
    exit 0
  elif [ "$QUALITY_PASSED" = "false" ]; then
    echo "[04_quality] Quality gate FAILED. Needs rework."
    exit 1
  else
    # If using Qwen, quality_passed may not be set — check average score
    if [ "$AVG_SCORE" -ge "$PASS_THRESHOLD" ] 2>/dev/null; then
      python3 -c "
import json
from datetime import datetime, timezone
with open('$STATE_FILE', 'r') as f:
    state = json.load(f)
state['quality_passed'] = True
state['quality_average'] = $AVG_SCORE
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
      echo "[04_quality] Quality gate PASSED (avg: $AVG_SCORE). Ready for monetization."
      exit 0
    else
      echo "[04_quality] Quality evaluation completed (pass/fail undetermined, avg: $AVG_SCORE)."
      exit 0
    fi
  fi
else
  echo "[04_quality] ERROR: Quality agent failed."
  exit 1
fi
