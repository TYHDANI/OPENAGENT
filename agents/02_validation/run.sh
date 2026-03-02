#!/usr/bin/env bash
# OPENAGENT — 02_validation agent launcher
# Validates research findings and produces a one-pager for the app concept.
# Usage: run.sh <project_dir>

set -euo pipefail

PROJECT_DIR="${1:?Usage: run.sh <project_dir>}"
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

source "$ROOT_DIR/orchestrator/model_router.sh"
source "$ROOT_DIR/orchestrator/qwen_call.sh"
MODEL=$(get_model "validation")
AGENT_MD="$AGENT_DIR/AGENT.md"
STATE_FILE="$PROJECT_DIR/state.json"
RESEARCH_DIR="$ROOT_DIR/agents/01_research/templates"

# ── Validate inputs ─────────────────────────────────────────────
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[02_validation] ERROR: Project directory not found: $PROJECT_DIR"
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

# ── Read opportunity data from research ─────────────────────────
OPPORTUNITY_DATA=""
if [ -f "$RESEARCH_DIR/opportunity.jsonl" ]; then
  OPPORTUNITY_DATA="$(cat "$RESEARCH_DIR/opportunity.jsonl")"
fi

# ── Read user idea if present ───────────────────────────────────
IDEA_CONTEXT=""
if [ -f "$PROJECT_DIR/idea.md" ]; then
  IDEA_CONTEXT="$(cat "$PROJECT_DIR/idea.md")"
fi

# ── Build the prompt ────────────────────────────────────────────
PROMPT="$(cat <<PROMPT_EOF
${AGENT_PROMPT}

=== PROJECT STATE ===
${STATE_CONTEXT:-No state.json found.}

=== OPPORTUNITY DATA (from research phase) ===
${OPPORTUNITY_DATA:-No opportunity data found in research templates.}

=== USER IDEA ===
${IDEA_CONTEXT:-No user idea file for this project.}

=== INSTRUCTIONS ===
You are the Validation agent for OPENAGENT. Your job:
1. Read the opportunity data from the research phase.
2. Validate the concept: Is there real demand? Is the competition beatable? Can we build it?
3. Produce a one-pager document at: ${PROJECT_DIR}/one_pager.md
4. The one-pager must include:
   - App Name (proposed)
   - Tagline (one sentence)
   - Problem Statement
   - Target Audience
   - Key Features (3-5 bullet points)
   - Monetization Strategy (freemium, subscription, one-time)
   - Competition Analysis (top 3 competitors, their weaknesses)
   - Unique Value Proposition
   - Technical Feasibility Assessment
   - Go/No-Go Recommendation with confidence score (1-10)
5. Update the project state.json at: ${STATE_FILE}
6. If Go: set status to "active", phase_name to "validation".
7. If No-Go: set status to "rejected" with a reason field.

OUTPUT FORMAT: Wrap each output file in markers like this:
===FILE: one_pager.md===
[content here]
===ENDFILE===

Files to produce:
- one_pager.md (the complete one-pager document)

Working directory: ${PROJECT_DIR}
Root directory: ${ROOT_DIR}
PROMPT_EOF
)"

# ── Execute agent (Qwen or Claude) ────────────────────────────────
echo "[02_validation] Starting validation agent for: $(basename "$PROJECT_DIR")"
echo "[02_validation] Model: $MODEL ($(model_tier "$MODEL")) | Backend: $(get_backend "$MODEL")"

if run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "validation_completed" "true"; then
  echo "[02_validation] Validation phase completed successfully."
  exit 0
else
  echo "[02_validation] ERROR: Validation agent failed."
  exit 1
fi
