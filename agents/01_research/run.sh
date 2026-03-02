#!/usr/bin/env bash
# OPENAGENT — 01_research agent launcher
# Researches App Store opportunities and evaluates user-submitted ideas.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# ── Source model router, Brave search, and Qwen wrapper ──────────
source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/brave_search.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "research")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
IDEAS_DIR="$ROOT_DIR/ideas"
TEMPLATES_DIR="$AGENT_DIR/templates"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[01_research] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Check for user-submitted ideas (priority) ───────────────────
IDEA_CONTEXT=""
IDEA_FILE="$PROJECT_DIR/idea.md"
if [ -f "$IDEA_FILE" ]; then
  IDEA_CONTEXT="$(cat "$IDEA_FILE")"
fi

# Also scan ideas/ for any unprocessed ideas
UNPROCESSED_IDEAS=""
if [ -d "$IDEAS_DIR" ]; then
  for f in "$IDEAS_DIR"/*.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    UNPROCESSED_IDEAS="${UNPROCESSED_IDEAS}
--- $(basename "$f") ---
$(cat "$f")
"
  done
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found — this may be a new project.}

=== USER-SUBMITTED IDEA ===
${IDEA_CONTEXT:-No user idea file found for this project.}

=== UNPROCESSED IDEAS IN ideas/ DIRECTORY ===
${UNPROCESSED_IDEAS:-No unprocessed ideas found.}

=== INSTRUCTIONS ===
You are the Research agent for OPENAGENT. Your job:
1. If a user-submitted idea exists (above), evaluate it as the primary opportunity.
2. Otherwise, research the App Store for underserved niches and emerging opportunities.
3. Produce structured findings as JSON lines.
4. Write your findings to: ${TEMPLATES_DIR}/opportunity.jsonl (append, do not overwrite existing entries).
5. Each line must be valid JSON with fields: {"opportunity_id", "title", "category", "gap_description", "target_audience", "competition_level", "estimated_demand", "monetization_potential", "score", "source", "timestamp"}
6. Also update the project state.json at: ${STATE_FILE}
7. Set phase_name to "research" and status to "active" in state.json.

OUTPUT FORMAT: Wrap each output file in markers like this:
===FILE: research_report.md===
[content here]
===ENDFILE===

Files to produce:
- research_report.md (your full research findings)

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Pre-fetch Brave search data to enrich context (saves tokens) ──
echo "[01_research] Fetching Brave search data..."
BRAVE_CONTEXT=""
PROJECT_NAME="$(basename "$PROJECT_DIR")"

if [ -n "$IDEA_CONTEXT" ]; then
  # If we have a user idea, search for market data about it
  IDEA_TITLE=$(echo "$IDEA_CONTEXT" | head -5 | tr '\n' ' ')
  BRAVE_RESULTS=$(brave_app_research "$IDEA_TITLE" 2>/dev/null || echo "")
  if [ -n "$BRAVE_RESULTS" ] && [ "$BRAVE_RESULTS" != '{"error": "combine failed"}' ]; then
    BRAVE_CONTEXT="
=== BRAVE SEARCH MARKET DATA ===
$BRAVE_RESULTS
"
  fi
else
  # No user idea — search for trending opportunities
  BRAVE_TRENDS=$(brave_trending_ideas "productivity" 2>/dev/null || echo "")
  if [ -n "$BRAVE_TRENDS" ]; then
    BRAVE_CONTEXT="
=== BRAVE SEARCH TRENDING IDEAS ===
$BRAVE_TRENDS
"
  fi
fi

# Append Brave data to prompt if available
if [ -n "$BRAVE_CONTEXT" ]; then
  PROMPT="${PROMPT}
${BRAVE_CONTEXT}"
fi

# ── Execute agent (Qwen or Claude) ────────────────────────────────
echo "[01_research] Starting research agent for: $PROJECT_NAME"
echo "[01_research] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "research_completed" "true"; then
  echo "[01_research] Research phase completed successfully."
  exit 0
else
  echo "[01_research] ERROR: Research agent failed."
  exit 1
fi
