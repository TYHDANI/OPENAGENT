#!/usr/bin/env bash
set -euo pipefail

# performance_check.sh — Performance static analysis for iOS/Swift projects
# Usage: performance_check.sh <project_dir>
# Outputs: score 0-10 on stdout (deduct per issue found, minimum 0)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: performance_check.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

ISSUES=0
DETAILS=""

# Exclude common vendored/generated directories
EXCLUDE_DIRS="--exclude-dir=Pods --exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=Carthage --exclude-dir=.git"

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
check_pattern() {
    local label="$1"
    local pattern="$2"
    local deduction="$3"
    local description="$4"

    # shellcheck disable=SC2086
    local matches
    matches=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
        -E "$pattern" "$PROJECT_DIR" 2>/dev/null || true)

    if [[ -n "$matches" ]]; then
        local count
        count=$(echo "$matches" | wc -l | xargs)
        local penalty=$((count * deduction))
        ISSUES=$((ISSUES + penalty))
        DETAILS="${DETAILS}\n[$label] $count occurrence(s) — $description (-${deduction} each)"
        echo "$matches" | head -3 | while IFS= read -r line; do
            echo "  $line" >&2
        done
        if [[ "$count" -gt 3 ]]; then
            echo "  ... and $((count - 3)) more" >&2
        fi
    fi
}

echo "Running performance analysis on: $PROJECT_DIR" >&2

# ---------------------------------------------------------------------------
# 1. Large images loaded without LazyImage / AsyncImage
#    Detect UIImage(named:) or Image() without lazy loading in ScrollViews
# ---------------------------------------------------------------------------
check_pattern "SYNC_IMAGE_IN_LIST" \
    'Image\(\s*"[^"]+"\s*\)' \
    1 \
    "Image() with string literal (consider AsyncImage for remote/large images)"

# ---------------------------------------------------------------------------
# 2. Excessive view body complexity — bodies with too many nested views
#    Heuristic: body computed property longer than reasonable
# ---------------------------------------------------------------------------
# Check for deeply nested VStack/HStack/ZStack (4+ levels)
# shellcheck disable=SC2086
DEEP_NESTING=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E "(VStack|HStack|ZStack)\s*\{" "$PROJECT_DIR" 2>/dev/null || true)

if [[ -n "$DEEP_NESTING" ]]; then
    NESTING_COUNT=$(echo "$DEEP_NESTING" | wc -l | xargs)
    # Only flag if excessive (>30 stack containers suggests complex views)
    if [[ "$NESTING_COUNT" -gt 30 ]]; then
        PENALTY=$(( (NESTING_COUNT - 30) / 10 ))
        if [[ "$PENALTY" -gt 0 ]]; then
            ISSUES=$((ISSUES + PENALTY))
            DETAILS="${DETAILS}\n[COMPLEX_VIEWS] $NESTING_COUNT stack containers — consider extracting subviews (-1 per 10 over 30)"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3. Missing .task cancellation — .task{} without checking Task.isCancelled
# ---------------------------------------------------------------------------
# shellcheck disable=SC2086
TASK_BLOCKS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -c '\.task\s*\{' "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

# shellcheck disable=SC2086
TASK_CANCELLED=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -c 'Task\.isCancelled\|Task\.checkCancellation' "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

if [[ "$TASK_BLOCKS" -gt 0 ]] && [[ "$TASK_CANCELLED" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[TASK_CANCELLATION] $TASK_BLOCKS .task{} block(s) without Task.isCancelled checks (-1)"
fi

# ---------------------------------------------------------------------------
# 4. Force unwrapping (!) — potential runtime crashes
# ---------------------------------------------------------------------------
check_pattern "FORCE_UNWRAP" \
    '[a-zA-Z_][a-zA-Z0-9_]*!' \
    0 \
    "Force unwrap detected (crash risk — informational, no deduction)"

# Actually count only dangerous force unwraps (exclude IBOutlet, common patterns)
# shellcheck disable=SC2086
FORCE_UNWRAPS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E '\w+!\.' "$PROJECT_DIR" 2>/dev/null \
    | grep -v '@IBOutlet' \
    | grep -v '// swiftlint:disable' \
    | wc -l | xargs)

if [[ "$FORCE_UNWRAPS" -gt 5 ]]; then
    PENALTY=$(( (FORCE_UNWRAPS - 5) / 5 ))
    if [[ "$PENALTY" -gt 0 ]]; then
        ISSUES=$((ISSUES + PENALTY))
        DETAILS="${DETAILS}\n[FORCE_UNWRAP_EXCESS] $FORCE_UNWRAPS force unwraps (>5 threshold, -1 per 5 over)"
    fi
fi

# ---------------------------------------------------------------------------
# 5. Synchronous network calls on main thread
# ---------------------------------------------------------------------------
check_pattern "SYNC_URL_REQUEST" \
    'URLSession\.shared\.data\(from:|NSURLConnection\.sendSynchronousRequest' \
    2 \
    "Potentially synchronous network call (use async/await)"

# ---------------------------------------------------------------------------
# 6. Large asset catalogs without optimization hints
# ---------------------------------------------------------------------------
ASSET_CATALOGS=$(find "$PROJECT_DIR" -name "*.xcassets" -not -path "*/Pods/*" 2>/dev/null)
if [[ -n "$ASSET_CATALOGS" ]]; then
    TOTAL_ASSETS=0
    while IFS= read -r catalog; do
        COUNT=$(find "$catalog" -name "*.imageset" 2>/dev/null | wc -l | xargs)
        TOTAL_ASSETS=$((TOTAL_ASSETS + COUNT))
    done <<< "$ASSET_CATALOGS"

    if [[ "$TOTAL_ASSETS" -gt 50 ]]; then
        ISSUES=$((ISSUES + 1))
        DETAILS="${DETAILS}\n[LARGE_ASSET_CATALOG] $TOTAL_ASSETS image assets — consider on-demand resources (-1)"
    fi
    echo "Asset catalogs: $TOTAL_ASSETS total image assets" >&2
fi

# ---------------------------------------------------------------------------
# 7. Missing @MainActor on ObservableObject classes
# ---------------------------------------------------------------------------
# shellcheck disable=SC2086
OBS_OBJECTS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E 'class\s+\w+\s*:\s*(ObservableObject|NSObject.*ObservableObject)' "$PROJECT_DIR" 2>/dev/null || true)

if [[ -n "$OBS_OBJECTS" ]]; then
    OBS_COUNT=$(echo "$OBS_OBJECTS" | wc -l | xargs)
    # shellcheck disable=SC2086
    MAIN_ACTOR_OBS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
        -B1 'class\s+\w+\s*:\s*ObservableObject' "$PROJECT_DIR" 2>/dev/null \
        | grep -c '@MainActor' || echo "0")

    MISSING_MAIN_ACTOR=$((OBS_COUNT - MAIN_ACTOR_OBS))
    if [[ "$MISSING_MAIN_ACTOR" -gt 0 ]]; then
        ISSUES=$((ISSUES + MISSING_MAIN_ACTOR))
        DETAILS="${DETAILS}\n[MISSING_MAINACTOR] $MISSING_MAIN_ACTOR ObservableObject class(es) without @MainActor (-1 each)"
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "" >&2
if [[ -n "$DETAILS" ]]; then
    echo -e "Performance issues found:" >&2
    echo -e "$DETAILS" >&2
fi

echo "" >&2
echo "Total performance deductions: $ISSUES" >&2

# Score: 10 minus total deductions, minimum 0
SCORE=$((10 - ISSUES))
if [[ "$SCORE" -lt 0 ]]; then
    SCORE=0
fi

echo "Performance score: $SCORE" >&2
echo "$SCORE"
exit 0
