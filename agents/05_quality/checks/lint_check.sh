#!/usr/bin/env bash
set -euo pipefail

# lint_check.sh — SwiftLint analysis for iOS/Swift projects
# Usage: lint_check.sh <project_dir>
# Outputs: score 0-10 on stdout (deduct 1 per warning, 2 per error, minimum 0)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: lint_check.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

# Check if SwiftLint is available
if ! command -v swiftlint &>/dev/null; then
    echo "WARNING: SwiftLint not found in PATH, attempting brew path" >&2
    if [[ -x "/opt/homebrew/bin/swiftlint" ]]; then
        SWIFTLINT="/opt/homebrew/bin/swiftlint"
    elif [[ -x "/usr/local/bin/swiftlint" ]]; then
        SWIFTLINT="/usr/local/bin/swiftlint"
    else
        echo "ERROR: SwiftLint is not installed. Install via: brew install swiftlint" >&2
        exit 1
    fi
else
    SWIFTLINT="swiftlint"
fi

echo "Using SwiftLint: $SWIFTLINT" >&2

# Find Swift source files
SWIFT_FILES=$(find "$PROJECT_DIR" -name "*.swift" \
    -not -path "*/Pods/*" \
    -not -path "*/.build/*" \
    -not -path "*/DerivedData/*" \
    -not -path "*/Carthage/*" \
    -not -path "*/*.generated.swift" \
    2>/dev/null)

SWIFT_COUNT=$(echo "$SWIFT_FILES" | grep -c "." 2>/dev/null || echo "0")

if [[ "$SWIFT_COUNT" -eq 0 ]]; then
    echo "WARNING: No Swift source files found in $PROJECT_DIR" >&2
    echo 10
    exit 0
fi

echo "Found $SWIFT_COUNT Swift file(s) to lint" >&2

# Run SwiftLint
LINT_LOG=$(mktemp /tmp/lint_check.XXXXXX.log)
trap "rm -f '$LINT_LOG'" EXIT

$SWIFTLINT lint --path "$PROJECT_DIR" --reporter json 2>/dev/null > "$LINT_LOG" || true

# Parse JSON output for warning/error counts
if command -v python3 &>/dev/null; then
    COUNTS=$(python3 -c "
import json, sys
try:
    with open('$LINT_LOG') as f:
        issues = json.load(f)
    warnings = sum(1 for i in issues if i.get('severity', '').lower() == 'warning')
    errors = sum(1 for i in issues if i.get('severity', '').lower() == 'error')
    print(f'{warnings} {errors}')
except Exception as e:
    print('0 0', file=sys.stdout)
    print(f'JSON parse error: {e}', file=sys.stderr)
" 2>&2)
    WARNINGS=$(echo "$COUNTS" | awk '{print $1}')
    ERRORS=$(echo "$COUNTS" | awk '{print $2}')
else
    # Fallback: run again with default reporter and count
    LINT_TEXT=$(mktemp /tmp/lint_text.XXXXXX.log)
    $SWIFTLINT lint --path "$PROJECT_DIR" 2>/dev/null > "$LINT_TEXT" || true
    WARNINGS=$(grep -ci "warning:" "$LINT_TEXT" 2>/dev/null || echo "0")
    ERRORS=$(grep -ci "error:" "$LINT_TEXT" 2>/dev/null || echo "0")
    rm -f "$LINT_TEXT"
fi

echo "SwiftLint results: warnings=$WARNINGS, errors=$ERRORS" >&2

# Log top issues for visibility
if [[ -s "$LINT_LOG" ]] && command -v python3 &>/dev/null; then
    python3 -c "
import json
try:
    with open('$LINT_LOG') as f:
        issues = json.load(f)
    for issue in issues[:10]:
        sev = issue.get('severity', '?')
        rule = issue.get('rule_id', '?')
        file = issue.get('file', '?').split('/')[-1]
        line = issue.get('line', '?')
        print(f'  [{sev}] {file}:{line} — {rule}')
    if len(issues) > 10:
        print(f'  ... and {len(issues) - 10} more issue(s)')
except:
    pass
" >&2
fi

# Score: 10 - (1 * warnings) - (2 * errors), minimum 0
SCORE=$((10 - WARNINGS - ERRORS * 2))
if [[ "$SCORE" -lt 0 ]]; then
    SCORE=0
fi

echo "Lint score: $SCORE" >&2
echo "$SCORE"
exit 0
