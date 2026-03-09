#!/usr/bin/env bash
# OPENAGENT Orchestrator — LITTLEGREENMAN
# Cron entry: */5 * * * * cd /Users/beachbar/OPENAGENT && ./orchestrator/littlegreenman.sh
#
# Scans projects for active state, determines next pipeline step,
# spawns Claude Code CLI sessions per agent.

set -euo pipefail

# Ensure claude CLI and required tools are on PATH
export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

# Allow nested Claude sessions (orchestrator spawns Claude CLI agents)
unset CLAUDECODE 2>/dev/null || true

# Source API keys from .env.openagent (works on both Mac and VPS)
ENV_FILE="$HOME/.env.openagent"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Unset ANTHROPIC_API_KEY if empty — Claude CLI uses CLAUDE_CODE_OAUTH_TOKEN (Max plan)
# Only keep API key if it was explicitly set with a real value
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  unset ANTHROPIC_API_KEY 2>/dev/null || true
fi
export APIFY_API_KEY="${APIFY_API_KEY:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="$ROOT_DIR/projects"
IDEAS_DIR="$ROOT_DIR/ideas"
AGENTS_DIR="$ROOT_DIR/agents"
LOGS_DIR="$ROOT_DIR/logs"
LOCKFILE="$ROOT_DIR/.littlegreenman.lock"

# Phase directories in pipeline order (12-phase v2 pipeline)
PHASES=(
  "01_research"
  "02_validation"
  "03_build"
  "04_code_review"
  "05_quality"
  "06_monetization"
  "07_appstore_prep"
  "08_onboarding"
  "09_screenshots"
  "10_promo"
  "11_launch"
  "12_growth"
)

# ── Logging helpers ──────────────────────────────────────────────

log_decision() {
  local project="$1" agent="$2" decision="$3" reason="$4"
  printf '{"timestamp":"%s","project":"%s","agent":"%s","decision":"%s","reason":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$project" "$agent" "$decision" "$reason" \
    >> "$LOGS_DIR/decisions.jsonl"
}

log_failure() {
  local project="$1" agent="$2" error="$3" recovery="$4"
  printf '{"timestamp":"%s","project":"%s","agent":"%s","error":"%s","recovery":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$project" "$agent" "$error" "$recovery" \
    >> "$LOGS_DIR/failures.jsonl"
}

log_cost() {
  local project="$1" agent="$2" model="$3" input_tokens="$4" output_tokens="$5" cost="$6"
  printf '{"timestamp":"%s","project":"%s","agent":"%s","model":"%s","input_tokens":%d,"output_tokens":%d,"cost_usd":%.4f}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$project" "$agent" "$model" "$input_tokens" "$output_tokens" "$cost" \
    >> "$LOGS_DIR/costs.jsonl"
}

# ── Lock management ──────────────────────────────────────────────

acquire_lock() {
  if [ -f "$LOCKFILE" ]; then
    local lock_pid
    lock_pid=$(cat "$LOCKFILE" 2>/dev/null || echo "")
    if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
      echo "[littlegreenman] Another instance running (PID $lock_pid). Exiting."
      exit 0
    fi
    echo "[littlegreenman] Stale lock found. Removing."
    rm -f "$LOCKFILE"
  fi
  echo $$ > "$LOCKFILE"
}

release_lock() {
  rm -f "$LOCKFILE"
}

trap release_lock EXIT

# ── Daily cost check ─────────────────────────────────────────────

check_daily_cost() {
  local today limit=50.00
  today=$(date -u +%Y-%m-%d)

  if [ ! -f "$LOGS_DIR/costs.jsonl" ]; then
    return 0
  fi

  local total
  total=$(grep "\"$today" "$LOGS_DIR/costs.jsonl" 2>/dev/null \
    | python3 -c "
import sys, json
total = 0
for line in sys.stdin:
    line = line.strip()
    if line:
        try:
            total += json.loads(line).get('cost_usd', 0)
        except: pass
print(f'{total:.2f}')
" 2>/dev/null || echo "0.00")

  if python3 -c "exit(0 if float('$total') >= float('$limit') else 1)" 2>/dev/null; then
    echo "[littlegreenman] Daily cost limit reached (\$$total >= \$$limit). Pausing."
    log_decision "SYSTEM" "orchestrator" "pause_all" "Daily cost limit \$$total >= \$$limit"
    return 1
  fi
  return 0
}

# ── Process user ideas ───────────────────────────────────────────

process_ideas() {
  for idea_file in "$IDEAS_DIR"/*.md; do
    [ -f "$idea_file" ] || continue
    [ "$(basename "$idea_file")" = "README.md" ] && continue

    local idea_name
    idea_name=$(basename "$idea_file" .md | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    local project_dir="$PROJECTS_DIR/$idea_name"

    if [ -d "$project_dir" ]; then
      continue  # Already created
    fi

    echo "[littlegreenman] New idea found: $idea_name"
    mkdir -p "$project_dir"
    cp "$PROJECTS_DIR/_template/state.json" "$project_dir/state.json"

    # Update state with idea info
    python3 -c "
import json
from datetime import datetime, timezone
with open('$project_dir/state.json', 'r') as f:
    state = json.load(f)
state['name'] = '$idea_name'
state['source'] = 'user_idea'
state['created_at'] = datetime.now(timezone.utc).isoformat()
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$project_dir/state.json', 'w') as f:
    json.dump(state, f, indent=2)
"
    # Copy idea file into project
    cp "$idea_file" "$project_dir/idea.md"
    mv "$idea_file" "$idea_file.processed"

    log_decision "$idea_name" "orchestrator" "create_project" "User idea submitted"
  done
}

# ── Count active projects ────────────────────────────────────────

count_active() {
  local count=0
  for state_file in "$PROJECTS_DIR"/*/state.json; do
    [ -f "$state_file" ] || continue
    local status
    status=$(python3 -c "import json; print(json.load(open('$state_file'))['status'])" 2>/dev/null || echo "unknown")
    if [ "$status" = "active" ]; then
      count=$((count + 1))
    fi
  done
  echo "$count"
}

# ── Run agent for a project ──────────────────────────────────────

run_agent() {
  local project_name="$1" phase_num="$2"
  local phase_dir="${PHASES[$((phase_num - 1))]}"
  local agent_dir="$AGENTS_DIR/$phase_dir"
  local project_dir="$PROJECTS_DIR/$project_name"
  local agent_md="$agent_dir/AGENT.md"
  local run_script="$agent_dir/run.sh"

  if [ ! -f "$run_script" ]; then
    log_failure "$project_name" "$phase_dir" "run.sh not found" "skipping"
    return 1
  fi

  echo "[littlegreenman] Running $phase_dir for project: $project_name"
  log_decision "$project_name" "$phase_dir" "start_phase" "Phase $phase_num triggered by orchestrator"

  # Execute the agent's run script with project context
  if bash "$run_script" "$project_dir" 2>&1 | tee -a "$LOGS_DIR/agent_${phase_dir}_${project_name}.log"; then
    # Advance to next phase (use dispatched phase_num to avoid double-advance)
    local next_phase=$((phase_num + 1))
    python3 -c "
import json
from datetime import datetime, timezone
next_phase = $next_phase
with open('$project_dir/state.json', 'r') as f:
    state = json.load(f)
# Only advance if the agent hasn't already advanced past us
if state.get('phase', 0) <= next_phase:
    state['phase'] = min(next_phase, 13)
    phases = ['research','validation','build','code_review','quality','monetization','appstore_prep','onboarding','screenshots','promo','launch','growth']
    if state['phase'] <= 12:
        state['phase_name'] = phases[state['phase'] - 1]
    else:
        state['phase_name'] = 'shipped'
        state['status'] = 'shipped'
state['fail_count'] = 0
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$project_dir/state.json', 'w') as f:
    json.dump(state, f, indent=2)
"
    log_decision "$project_name" "$phase_dir" "phase_complete" "Advanced to phase $((phase_num + 1))"
    # Notify Discord with rich embed
    if [ -f "$SCRIPT_DIR/discord_notify.sh" ]; then
      bash "$SCRIPT_DIR/discord_notify.sh" \
        "**$project_name** completed **$phase_dir** → advancing to phase $((phase_num + 1))" \
        "green" \
        "✅ Phase Complete" 2>/dev/null || true
    fi
  else
    # Handle failure
    python3 -c "
import json
from datetime import datetime, timezone
with open('$project_dir/state.json', 'r') as f:
    state = json.load(f)
state['fail_count'] = state.get('fail_count', 0) + 1
if state['fail_count'] >= 3:
    state['status'] = 'paused'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$project_dir/state.json', 'w') as f:
    json.dump(state, f, indent=2)
"
    local fail_count
    fail_count=$(python3 -c "import json; print(json.load(open('$project_dir/state.json')).get('fail_count', 0))" 2>/dev/null)
    if [ "$fail_count" -ge 3 ]; then
      log_failure "$project_name" "$phase_dir" "3 consecutive failures" "paused for manual review"
      # Alert Discord about pause
      if [ -f "$SCRIPT_DIR/discord_notify.sh" ]; then
        bash "$SCRIPT_DIR/discord_notify.sh" \
          "**$project_name** paused after 3 failures in **$phase_dir** — needs manual review" \
          "red" \
          "⚠️ Project Paused" 2>/dev/null || true
      fi
    else
      log_failure "$project_name" "$phase_dir" "phase failed" "will retry next cycle (fail $fail_count/3)"
    fi
    return 1
  fi
}

# ── Main orchestrator loop ────────────────────────────────────────

main() {
  echo "[littlegreenman] ════════════════════════════════════════════════"
  echo "[littlegreenman] Cycle started at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  acquire_lock

  # Check daily cost limit
  if ! check_daily_cost; then
    exit 0
  fi

  # Process any new user ideas
  process_ideas

  # Count active projects first
  local total_active
  total_active=$(count_active)
  echo "[littlegreenman] Active projects: $total_active"

  # Get scheduler priority queue
  local queue
  queue=$(python3 "$SCRIPT_DIR/scheduler.py" "$PROJECTS_DIR" 2>/dev/null || echo "")

  if [ -z "$queue" ]; then
    echo "[littlegreenman] No active projects to process."
    exit 0
  fi

  # Send cycle summary to Discord
  if [ -f "$SCRIPT_DIR/discord_notify.sh" ]; then
    local summary
    summary=$(echo "$queue" | while IFS='|' read -r pname pnum; do
      [ -z "$pname" ] && continue
      echo "• **$pname** → phase $pnum"
    done)
    bash "$SCRIPT_DIR/discord_notify.sh" \
      "Processing $total_active active projects this cycle:\n$summary" \
      "blue" \
      "🔄 Pipeline Cycle" 2>/dev/null || true
  fi

  # Track agents spawned this cycle (max 5 concurrent agents per cycle)
  local spawned=0

  # Process each project from the priority queue
  while IFS='|' read -r project_name phase_num; do
    [ -z "$project_name" ] && continue

    # Limit concurrent agent spawns per cycle
    if [ "$spawned" -ge 5 ]; then
      echo "[littlegreenman] Max concurrent agents reached (5). Deferring $project_name."
      log_decision "$project_name" "orchestrator" "deferred" "Max concurrent agents per cycle reached"
      continue
    fi

    run_agent "$project_name" "$phase_num" &
    spawned=$((spawned + 1))
  done <<< "$queue"

  # Wait for all background agents to complete
  wait

  echo "[littlegreenman] Cycle complete at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "[littlegreenman] ════════════════════════════════════════════════"
}

main "$@"
