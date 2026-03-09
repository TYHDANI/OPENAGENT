#!/bin/bash
# OPENAGENT Pipeline Monitor — Analytics Dashboard
# Inspired by: claude-code-templates analytics/monitoring
# Provides real-time pipeline status and project health overview
# Usage: ./pipeline_monitor.sh [--json|--table|--watch]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="$ROOT_DIR/projects"

# Phase names for the enhanced 12-phase pipeline
PHASES=(
    "1:research"
    "2:validation"
    "3:build"
    "4:code_review"
    "5:quality"
    "6:monetization"
    "7:appstore_prep"
    "8:onboarding"
    "9:screenshots"
    "10:promo"
    "11:launch"
    "12:growth"
)

get_phase_name() {
    local phase_num=$1
    for p in "${PHASES[@]}"; do
        local num="${p%%:*}"
        local name="${p#*:}"
        if [ "$num" = "$phase_num" ]; then
            echo "$name"
            return
        fi
    done
    echo "unknown"
}

# Generate pipeline status table
show_table() {
    echo ""
    echo "╔══════════════════════╦═══════╦════════════════╦══════════╦═══════════╦════════╗"
    echo "║ App                  ║ Phase ║ Phase Name     ║ Status   ║ Score Avg ║ Fails  ║"
    echo "╠══════════════════════╬═══════╬════════════════╬══════════╬═══════════╬════════╣"

    for state_file in "$PROJECTS_DIR"/*/state.json; do
        [ -f "$state_file" ] || continue

        local name=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('name','?'))" 2>/dev/null)
        local phase=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('phase',0))" 2>/dev/null)
        local phase_name=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('phase_name','?'))" 2>/dev/null)
        local status=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('status','?'))" 2>/dev/null)
        local fail_count=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('fail_count',0))" 2>/dev/null)
        local scores=$(python3 -c "
import json
d=json.load(open('$state_file'))
s=d.get('scores',{})
vals=[v for v in s.values() if v > 0]
avg=sum(vals)/len(vals) if vals else 0
print(f'{avg:.1f}')
" 2>/dev/null)

        printf "║ %-20s ║ %5s ║ %-14s ║ %-8s ║ %9s ║ %6s ║\n" \
            "${name:0:20}" "$phase" "${phase_name:0:14}" "${status:0:8}" "$scores" "$fail_count"
    done

    echo "╚══════════════════════╩═══════╩════════════════╩══════════╩═══════════╩════════╝"
    echo ""
}

# Generate JSON status for remote monitoring
show_json() {
    python3 -c "
import json, os, glob
from datetime import datetime

projects = []
for state_file in sorted(glob.glob('$PROJECTS_DIR/*/state.json')):
    try:
        with open(state_file) as f:
            data = json.load(f)
            scores = data.get('scores', {})
            active_scores = [v for v in scores.values() if v > 0]
            projects.append({
                'name': data.get('name', 'Unknown'),
                'phase': data.get('phase', 0),
                'phase_name': data.get('phase_name', 'unknown'),
                'status': data.get('status', 'unknown'),
                'fail_count': data.get('fail_count', 0),
                'score_average': round(sum(active_scores) / len(active_scores), 1) if active_scores else 0,
                'scores': scores,
                'updated_at': data.get('updated_at', '')
            })
    except: pass

report = {
    'generated_at': datetime.utcnow().isoformat() + 'Z',
    'total_projects': len(projects),
    'pipeline_version': '2.0',
    'phases_total': 12,
    'projects': projects
}

print(json.dumps(report, indent=2))
" 2>/dev/null
}

# Pipeline progress bar
show_progress() {
    echo ""
    echo "Pipeline Progress (12 phases):"
    echo ""

    for state_file in "$PROJECTS_DIR"/*/state.json; do
        [ -f "$state_file" ] || continue

        local name=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('name','?'))" 2>/dev/null)
        local phase=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('phase',0))" 2>/dev/null)
        local status=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('status','?'))" 2>/dev/null)

        local bar=""
        for i in $(seq 1 12); do
            if [ "$i" -lt "$phase" ]; then
                bar+="█"
            elif [ "$i" -eq "$phase" ] && [ "$status" = "complete" ]; then
                bar+="█"
            elif [ "$i" -eq "$phase" ]; then
                bar+="▓"
            else
                bar+="░"
            fi
        done

        printf "  %-18s [%s] %s/%s (%s)\n" "${name:0:18}" "$bar" "$phase" "12" "$status"
    done
    echo ""
}

# Main
case "${1:-}" in
    --json)
        show_json
        ;;
    --table)
        show_table
        ;;
    --watch)
        while true; do
            clear
            echo "OPENAGENT Pipeline Monitor (v2.0) — $(date)"
            show_table
            show_progress
            sleep 30
        done
        ;;
    *)
        echo "OPENAGENT Pipeline Monitor (v2.0)"
        show_table
        show_progress
        ;;
esac
