#!/usr/bin/env bash
# OPENAGENT — Quick status of all active projects
# Usage: status.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS_DIR="$ROOT_DIR/projects"
LOGS_DIR="$ROOT_DIR/logs"

PHASES=("research" "validation" "build" "quality" "monetization" "appstore_prep" "onboarding" "screenshots" "promo")

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    OPENAGENT Status                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ── Summary stats ────────────────────────────────────────────────
ACTIVE=0; PAUSED=0; SHIPPED=0; FAILED=0; TOTAL=0

for state_file in "$PROJECTS_DIR"/*/state.json; do
  [ -f "$state_file" ] || continue
  [ "$(basename "$(dirname "$state_file")")" = "_template" ] && continue
  TOTAL=$((TOTAL + 1))

  status=$(python3 -c "import json; print(json.load(open('$state_file'))['status'])" 2>/dev/null || echo "unknown")
  case "$status" in
    active) ACTIVE=$((ACTIVE + 1)) ;;
    paused) PAUSED=$((PAUSED + 1)) ;;
    shipped) SHIPPED=$((SHIPPED + 1)) ;;
    failed) FAILED=$((FAILED + 1)) ;;
  esac
done

# Today's cost
TODAY=$(date -u +%Y-%m-%d)
TODAY_COST="0.00"
if [ -f "$LOGS_DIR/costs.jsonl" ]; then
  TODAY_COST=$(grep "$TODAY" "$LOGS_DIR/costs.jsonl" 2>/dev/null \
    | python3 -c "
import sys, json
total = 0
for line in sys.stdin:
    line = line.strip()
    if line:
        try: total += json.loads(line).get('cost_usd', 0)
        except: pass
print(f'{total:.2f}')
" 2>/dev/null || echo "0.00")
fi

printf "  Projects: %d total | %d active | %d paused | %d shipped | %d failed\n" \
  "$TOTAL" "$ACTIVE" "$PAUSED" "$SHIPPED" "$FAILED"
printf "  Today's cost: \$%s / \$50.00 limit\n" "$TODAY_COST"
echo ""

# ── Per-project status ───────────────────────────────────────────
if [ "$TOTAL" -eq 0 ]; then
  echo "  No projects yet. Drop an idea into ideas/ or run:"
  echo "    ./scripts/add_idea.sh \"My App Name\""
  echo ""
fi

if [ "$TOTAL" -gt 0 ]; then
printf "  %-20s %-12s %-6s %-20s %-8s %s\n" "PROJECT" "STATUS" "PHASE" "PHASE NAME" "FAILS" "COST"
printf "  %-20s %-12s %-6s %-20s %-8s %s\n" "───────" "──────" "─────" "──────────" "─────" "────"

for state_file in "$PROJECTS_DIR"/*/state.json; do
  [ -f "$state_file" ] || continue
  [ "$(basename "$(dirname "$state_file")")" = "_template" ] && continue

  python3 -c "
import json
with open('$state_file') as f:
    s = json.load(f)
name = s.get('name', '?')[:20]
status = s.get('status', '?')[:12]
phase = str(s.get('phase', 0))
phase_name = s.get('phase_name', '?')[:20]
fails = str(s.get('fail_count', 0))
cost = f\"\${s.get('cost_usd', 0):.2f}\"

# Phase progress bar
p = s.get('phase', 1)
bar = ''
for i in range(1, 10):
    if i < p: bar += '='
    elif i == p: bar += '>'
    else: bar += '.'

print(f'  {name:<20} {status:<12} {phase}/9    {phase_name:<20} {fails:<8} {cost}')
print(f'  Pipeline: [{bar}]')
print()
" 2>/dev/null
done
fi

# ── Pending ideas ────────────────────────────────────────────────
IDEAS_COUNT=$(find "$ROOT_DIR/ideas" -name "*.md" -not -name "README.md" 2>/dev/null | wc -l | xargs)
if [ "$IDEAS_COUNT" -gt 0 ]; then
  echo "  Pending ideas: $IDEAS_COUNT"
  for idea in "$ROOT_DIR/ideas"/*.md; do
    [ -f "$idea" ] || continue
    [ "$(basename "$idea")" = "README.md" ] && continue
    echo "    - $(basename "$idea" .md)"
  done
  echo ""
fi

# ── Recent failures ──────────────────────────────────────────────
if [ -f "$LOGS_DIR/failures.jsonl" ]; then
  FAILURE_COUNT=$( (grep -v '"_schema"' "$LOGS_DIR/failures.jsonl" 2>/dev/null || true) | wc -l | xargs)
  if [ "$FAILURE_COUNT" -gt 0 ]; then
    echo "  Recent failures (last 3):"
    (grep -v '"_schema"' "$LOGS_DIR/failures.jsonl" || true) | tail -3 | while IFS= read -r line; do
      python3 -c "
import json
e = json.loads('$line'.replace(\"'\", \"\"))
print(f\"    [{e.get('timestamp','?')[:19]}] {e.get('project','?')} / {e.get('agent','?')}: {e.get('error','?')}\")
" 2>/dev/null || true
    done
    echo ""
  fi
fi

echo "════════════════════════════════════════════════════════════════════"
echo "  Dashboard: python3 dashboard/server.py  (http://localhost:8420)"
echo "  Add idea:  ./scripts/add_idea.sh \"App Name\""
echo "  Run cycle: ./orchestrator/littlegreenman.sh"
echo "════════════════════════════════════════════════════════════════════"
