#!/bin/bash
# OPENAGENT Health Check — Pre-flight validation for littlegreenman.sh
# Inspired by: claude-code-templates health-check
# Run before every pipeline cycle to catch environment issues early

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "  ✓ $name"
        ((PASS++))
    else
        echo "  ✗ $name"
        ((FAIL++))
    fi
}

warn_check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "  ✓ $name"
        ((PASS++))
    else
        echo "  ⚠ $name (warning)"
        ((WARN++))
    fi
}

echo "═══════════════════════════════════════════"
echo "  OPENAGENT Health Check"
echo "═══════════════════════════════════════════"
echo ""

# Core tools
echo "Core Tools:"
check "Claude CLI" "which claude"
check "Xcode" "which xcodebuild"
check "Swift" "which swift"
check "Git" "which git"
check "Python 3" "which python3"
check "Node.js" "which node"

echo ""
echo "Environment:"
check "OPENAGENT root exists" "[ -d '$ROOT_DIR/projects' ]"
check "Ideas directory exists" "[ -d '$ROOT_DIR/ideas' ]"
check "Logs directory exists" "[ -d '$ROOT_DIR/logs' ]"
check "Agents directory exists" "[ -d '$ROOT_DIR/agents' ]"
check "Orchestrator exists" "[ -f '$ROOT_DIR/orchestrator/littlegreenman.sh' ]"
check "Config exists" "[ -f '$ROOT_DIR/orchestrator/config.yaml' ]"
check "DerivedData on SSD" "[ -d '/Volumes/T7/DerivedData' ]"

echo ""
echo "API Keys:"
warn_check "ANTHROPIC_API_KEY set" "[ -n \"\$ANTHROPIC_API_KEY\" ]"
warn_check "BRAVE_API_KEY_1 set" "[ -n \"\$BRAVE_API_KEY_1\" ]"
warn_check "CLAUDE_CODE_OAUTH_TOKEN set" "[ -n \"\$CLAUDE_CODE_OAUTH_TOKEN\" ]"

echo ""
echo "Integrations:"
warn_check "Scrapling installed" "[ -f '$ROOT_DIR/tools/scrapling/.venv/bin/python3' ]"
warn_check "MoneyPrinterV2 installed" "[ -f '$ROOT_DIR/tools/moneyprinter/.venv/bin/python3' ]"
warn_check "Brave Search script" "[ -f '$ROOT_DIR/orchestrator/brave_search.sh' ]"
warn_check "Scrapling search script" "[ -f '$ROOT_DIR/orchestrator/scrapling_search.sh' ]"

echo ""
echo "Pipeline State:"
TOTAL_PROJECTS=$(ls -d "$ROOT_DIR/projects"/*/state.json 2>/dev/null | wc -l | tr -d ' ')
ACTIVE_PROJECTS=$(grep -l '"status": "in_progress\|pending\|paused"' "$ROOT_DIR/projects"/*/state.json 2>/dev/null | wc -l | tr -d ' ')
COMPLETE_PROJECTS=$(grep -l '"status": "complete"' "$ROOT_DIR/projects"/*/state.json 2>/dev/null | wc -l | tr -d ' ')
echo "  Total projects: $TOTAL_PROJECTS"
echo "  Active: $ACTIVE_PROJECTS"
echo "  Complete phase: $COMPLETE_PROJECTS"

echo ""
echo "Disk Space:"
AVAILABLE=$(df -h /Volumes/T7 2>/dev/null | tail -1 | awk '{print $4}')
echo "  SSD available: ${AVAILABLE:-N/A}"
LOCAL_AVAILABLE=$(df -h / | tail -1 | awk '{print $4}')
echo "  Local available: $LOCAL_AVAILABLE"

echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "═══════════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
    echo "  STATUS: UNHEALTHY — fix $FAIL failed checks before running pipeline"
    exit 1
elif [ $WARN -gt 2 ]; then
    echo "  STATUS: DEGRADED — pipeline will run but some features unavailable"
    exit 0
else
    echo "  STATUS: HEALTHY — ready to run"
    exit 0
fi
