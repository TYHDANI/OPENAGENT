#!/usr/bin/env bash
set -euo pipefail

# design_review.sh — Design System compliance check for iOS/Swift projects
# Usage: design_review.sh <project_dir>
# Outputs: score 0-10 on stdout (deduct per violation, minimum 0)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: design_review.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

ISSUES=0
DETAILS=""

EXCLUDE_DIRS="--exclude-dir=Pods --exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=Carthage --exclude-dir=.git --exclude-dir=DesignSystem"

# Find SwiftUI files (exclude DesignSystem itself)
# shellcheck disable=SC2086
SWIFTUI_FILES=$(grep -rl --include="*.swift" $EXCLUDE_DIRS \
    -E 'import SwiftUI|: View\b' "$PROJECT_DIR" 2>/dev/null || true)

SWIFTUI_COUNT=0
if [[ -n "$SWIFTUI_FILES" ]]; then
    SWIFTUI_COUNT=$(echo "$SWIFTUI_FILES" | wc -l | xargs)
fi

echo "Found $SWIFTUI_COUNT SwiftUI view file(s)" >&2

if [[ "$SWIFTUI_COUNT" -eq 0 ]]; then
    echo "No SwiftUI files found — skipping design review" >&2
    echo 10
    exit 0
fi

# Helper: count grep matches safely (returns 0 if no matches)
count_matches() {
    local pattern="$1"
    local dir="$2"
    local raw
    # shellcheck disable=SC2086
    raw=$(grep -r --include="*.swift" $EXCLUDE_DIRS \
        -cE "$pattern" "$dir" 2>/dev/null || true)
    if [[ -z "$raw" ]]; then
        echo "0"
    else
        echo "$raw" | awk -F: '{s+=$2} END {print s+0}'
    fi
}

# ---------------------------------------------------------------------------
# 1. Hardcoded colors (should use AppColors)
# ---------------------------------------------------------------------------
echo "Checking: Hardcoded colors..." >&2

HARDCODED_COLORS=$(count_matches 'Color\.(blue|red|green|orange|yellow|purple|pink|cyan|mint|teal|indigo|brown|gray)\b|\.foregroundColor\(\.(white|black)\)' "$PROJECT_DIR")

echo "  Hardcoded colors: $HARDCODED_COLORS" >&2

if [[ "$HARDCODED_COLORS" -gt 0 ]]; then
    PENALTY=$(( (HARDCODED_COLORS + 4) / 5 ))
    ISSUES=$((ISSUES + PENALTY))
    DETAILS="${DETAILS}\n[HARDCODED_COLORS] $HARDCODED_COLORS direct Color.* usage(s) — use AppColors.* instead (-1 per 5)"
fi

# ---------------------------------------------------------------------------
# 2. Hardcoded spacing (should use AppSpacing)
# ---------------------------------------------------------------------------
echo "Checking: Hardcoded spacing..." >&2

HARDCODED_SPACING=$(count_matches '\.padding\(\s*[0-9]|\.padding\(\.\w+,\s*[0-9]|spacing:\s*[0-9]' "$PROJECT_DIR")

echo "  Hardcoded spacing: $HARDCODED_SPACING" >&2

if [[ "$HARDCODED_SPACING" -gt 0 ]]; then
    PENALTY=$(( (HARDCODED_SPACING + 4) / 5 ))
    ISSUES=$((ISSUES + PENALTY))
    DETAILS="${DETAILS}\n[HARDCODED_SPACING] $HARDCODED_SPACING hardcoded padding/spacing value(s) — use AppSpacing.* instead (-1 per 5)"
fi

# ---------------------------------------------------------------------------
# 3. Hardcoded fonts (should use AppTypography)
# ---------------------------------------------------------------------------
echo "Checking: Hardcoded fonts..." >&2

HARDCODED_FONTS=$(count_matches '\.font\(\s*\.system\(size:' "$PROJECT_DIR")

echo "  Hardcoded fonts: $HARDCODED_FONTS" >&2

if [[ "$HARDCODED_FONTS" -gt 0 ]]; then
    PENALTY=$(( (HARDCODED_FONTS + 4) / 5 ))
    ISSUES=$((ISSUES + PENALTY))
    DETAILS="${DETAILS}\n[HARDCODED_FONTS] $HARDCODED_FONTS .system(size:) font(s) — use AppTypography.* instead (-1 per 5)"
fi

# ---------------------------------------------------------------------------
# 4. Missing haptic feedback
# ---------------------------------------------------------------------------
echo "Checking: Haptic feedback..." >&2

HAPTICS=$(count_matches 'AppHaptics\.|\.sensoryFeedback\(|UIImpactFeedbackGenerator|UINotificationFeedbackGenerator|UISelectionFeedbackGenerator' "$PROJECT_DIR")

echo "  Haptic calls: $HAPTICS" >&2

if [[ "$HAPTICS" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[NO_HAPTICS] No haptic feedback found — use AppHaptics or .sensoryFeedback() (-1)"
fi

# ---------------------------------------------------------------------------
# 5. Bare ProgressView (should use ShimmerView)
# ---------------------------------------------------------------------------
echo "Checking: Loading states..." >&2

BARE_PROGRESS=$(count_matches 'ProgressView\(\)' "$PROJECT_DIR")
SHIMMER=$(count_matches 'ShimmerView' "$PROJECT_DIR")

echo "  Bare ProgressView: $BARE_PROGRESS, ShimmerView: $SHIMMER" >&2

if [[ "$BARE_PROGRESS" -gt 0 ]] && [[ "$SHIMMER" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[NO_SHIMMER] $BARE_PROGRESS bare ProgressView(s) — use ShimmerView for skeleton loading (-1)"
fi

# ---------------------------------------------------------------------------
# 6. Missing EmptyStateView
# ---------------------------------------------------------------------------
echo "Checking: Empty states..." >&2

EMPTY_STATE=$(count_matches 'AppEmptyStateView|EmptyStateView' "$PROJECT_DIR")
CONTENT_UNAVAILABLE=$(count_matches 'ContentUnavailableView' "$PROJECT_DIR")

echo "  AppEmptyStateView: $EMPTY_STATE, ContentUnavailableView: $CONTENT_UNAVAILABLE" >&2

if [[ "$EMPTY_STATE" -eq 0 ]] && [[ "$CONTENT_UNAVAILABLE" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[NO_EMPTY_STATE] No empty state views found — use AppEmptyStateView (-1)"
fi

# ---------------------------------------------------------------------------
# 7. Missing animations
# ---------------------------------------------------------------------------
echo "Checking: Animations..." >&2

ANIMATIONS=$(count_matches 'AppAnimation\.|\.animation\(|withAnimation|\.transition\(|\.matchedGeometryEffect|\.symbolEffect\(|\.contentTransition\(' "$PROJECT_DIR")

echo "  Animation calls: $ANIMATIONS" >&2

if [[ "$ANIMATIONS" -lt 3 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[LOW_ANIMATIONS] Only $ANIMATIONS animation(s) found — add AppAnimation.*, .symbolEffect, .contentTransition (-1)"
fi

# ---------------------------------------------------------------------------
# 8. Missing .refreshable
# ---------------------------------------------------------------------------
echo "Checking: Pull to refresh..." >&2

REFRESHABLE=$(count_matches '\.refreshable\s*\{' "$PROJECT_DIR")

echo "  .refreshable: $REFRESHABLE" >&2

if [[ "$REFRESHABLE" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[NO_REFRESHABLE] No .refreshable {} found — add pull-to-refresh on data screens (-1)"
fi

# ---------------------------------------------------------------------------
# 9. DesignSystem usage
# ---------------------------------------------------------------------------
echo "Checking: DesignSystem usage..." >&2

DS_USAGE=$(count_matches 'AppColors\.|AppTypography\.|AppSpacing\.|AppRadius\.|PremiumCard|PremiumButton' "$PROJECT_DIR")

echo "  DesignSystem token usage: $DS_USAGE" >&2

if [[ "$DS_USAGE" -lt 5 ]]; then
    ISSUES=$((ISSUES + 2))
    DETAILS="${DETAILS}\n[LOW_DS_USAGE] Only $DS_USAGE DesignSystem token usage(s) — should be pervasive (-2)"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "" >&2
if [[ -n "$DETAILS" ]]; then
    echo -e "Design System violations found:" >&2
    echo -e "$DETAILS" >&2
fi

echo "" >&2
echo "Total design deductions: $ISSUES" >&2

# Score: 10 minus deductions, minimum 0
SCORE=$((10 - ISSUES))
if [[ "$SCORE" -lt 0 ]]; then
    SCORE=0
fi

echo "Design review score: $SCORE" >&2
echo "$SCORE"
exit 0
