#!/bin/bash
# unpause_all.sh — Reset fail_count and set status=active for all paused projects
# Usage: bash orchestrator/unpause_all.sh [--dry-run]

PROJECTS_DIR="$(dirname "$0")/../projects"
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

UNPAUSED=0
SKIPPED=0

for state_file in "$PROJECTS_DIR"/*/state.json; do
    project_dir=$(dirname "$state_file")
    project_name=$(basename "$project_dir")

    # Skip template
    [[ "$project_name" == "_template" ]] && continue

    # Read current status
    current_status=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('status',''))" 2>/dev/null)

    # Skip scrapped projects
    if [[ "$current_status" == "scrapped" ]]; then
        echo "  SKIP  $project_name (scrapped)"
        ((SKIPPED++))
        continue
    fi

    # Skip already active
    if [[ "$current_status" == "active" ]]; then
        echo "  SKIP  $project_name (already active)"
        ((SKIPPED++))
        continue
    fi

    if $DRY_RUN; then
        echo "  WOULD UNPAUSE  $project_name (was: $current_status)"
        ((UNPAUSED++))
    else
        # Set status=active, fail_count=0, update timestamp
        python3 -c "
import json, datetime
with open('$state_file', 'r') as f:
    d = json.load(f)
d['status'] = 'active'
d['fail_count'] = 0
d['updated_at'] = datetime.datetime.utcnow().isoformat() + 'Z'
with open('$state_file', 'w') as f:
    json.dump(d, f, indent=2)
print(f'  UNPAUSED  $project_name  (phase {d.get(\"phase\",\"?\")} — {d.get(\"phase_name\",\"?\")})')
" 2>/dev/null
        ((UNPAUSED++))
    fi
done

echo ""
echo "Done: $UNPAUSED unpaused, $SKIPPED skipped"
echo "Pipeline will pick them up on the next cron cycle (every 5 minutes)."
