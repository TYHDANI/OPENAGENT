#!/usr/bin/env bash
set -euo pipefail

# ux_review.sh — UX/Accessibility review for iOS/Swift projects
# Usage: ux_review.sh <project_dir>
# Outputs: score 0-10 on stdout (deduct per accessibility issue, minimum 0)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: ux_review.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

ISSUES=0
DETAILS=""

EXCLUDE_DIRS="--exclude-dir=Pods --exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=Carthage --exclude-dir=.git"

# Find all Swift UI files (heuristic: files containing SwiftUI imports or View conformance)
# shellcheck disable=SC2086
SWIFTUI_FILES=$(grep -rl --include="*.swift" $EXCLUDE_DIRS \
    -E 'import SwiftUI|: View\b' "$PROJECT_DIR" 2>/dev/null || true)

SWIFTUI_COUNT=0
if [[ -n "$SWIFTUI_FILES" ]]; then
    SWIFTUI_COUNT=$(echo "$SWIFTUI_FILES" | wc -l | xargs)
fi

echo "Found $SWIFTUI_COUNT SwiftUI view file(s)" >&2

if [[ "$SWIFTUI_COUNT" -eq 0 ]]; then
    echo "No SwiftUI files found — skipping UX review" >&2
    echo 10
    exit 0
fi

# ---------------------------------------------------------------------------
# 1. Images without accessibility labels
#    Check for Image() calls that don't have .accessibilityLabel
# ---------------------------------------------------------------------------
echo "Checking: Image accessibility labels..." >&2

# Count Image() usages (excluding decorative)
# shellcheck disable=SC2086
IMAGE_CALLS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E 'Image\(\s*(systemName:\s*)?"[^"]*"\s*\)' "$PROJECT_DIR" 2>/dev/null || true)

IMAGE_COUNT=0
if [[ -n "$IMAGE_CALLS" ]]; then
    IMAGE_COUNT=$(echo "$IMAGE_CALLS" | wc -l | xargs)
fi

# Count Images with accessibility labels
# shellcheck disable=SC2086
ACCESSIBLE_IMAGES=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.accessibilityLabel\(|\.accessibility\(label:' "$PROJECT_DIR" 2>/dev/null \
    | awk -F: '{s+=$2} END {print s+0}')

# Count decorative images (explicitly marked as decorative)
# shellcheck disable=SC2086
DECORATIVE_IMAGES=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'Image\(decorative:|\.accessibilityHidden\(true\)' "$PROJECT_DIR" 2>/dev/null \
    | awk -F: '{s+=$2} END {print s+0}')

UNLABELED_IMAGES=$((IMAGE_COUNT - ACCESSIBLE_IMAGES - DECORATIVE_IMAGES))
if [[ "$UNLABELED_IMAGES" -lt 0 ]]; then
    UNLABELED_IMAGES=0
fi

if [[ "$UNLABELED_IMAGES" -gt 0 ]]; then
    # Deduct 1 per 3 unlabeled images
    PENALTY=$(( (UNLABELED_IMAGES + 2) / 3 ))
    ISSUES=$((ISSUES + PENALTY))
    DETAILS="${DETAILS}\n[MISSING_A11Y_LABEL] $UNLABELED_IMAGES image(s) without accessibility labels (-1 per 3)"
fi

echo "  Images: total=$IMAGE_COUNT, labeled=$ACCESSIBLE_IMAGES, decorative=$DECORATIVE_IMAGES, unlabeled=$UNLABELED_IMAGES" >&2

# ---------------------------------------------------------------------------
# 2. Buttons without sufficient tap targets (44pt minimum per HIG)
#    Check for .frame() modifiers with small sizes on buttons
# ---------------------------------------------------------------------------
echo "Checking: Button tap target sizes..." >&2

# shellcheck disable=SC2086
SMALL_BUTTONS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E 'Button.*\.frame\((width|height):\s*[0-9]{1,2}[^0-9]' "$PROJECT_DIR" 2>/dev/null || true)

SMALL_BUTTON_COUNT=0
if [[ -n "$SMALL_BUTTONS" ]]; then
    # Filter to only frames < 44
    SMALL_BUTTON_COUNT=$(echo "$SMALL_BUTTONS" | grep -cE '\b([0-9]|[1-3][0-9]|4[0-3])\b' 2>/dev/null || echo "0")
fi

if [[ "$SMALL_BUTTON_COUNT" -gt 0 ]]; then
    ISSUES=$((ISSUES + SMALL_BUTTON_COUNT))
    DETAILS="${DETAILS}\n[SMALL_TAP_TARGET] $SMALL_BUTTON_COUNT button(s) with frame < 44pt (HIG minimum) (-1 each)"
fi

echo "  Small tap targets: $SMALL_BUTTON_COUNT" >&2

# ---------------------------------------------------------------------------
# 3. Dynamic Type support — check for fixed font sizes
# ---------------------------------------------------------------------------
echo "Checking: Dynamic Type support..." >&2

# Check for hardcoded font sizes instead of dynamic type
# shellcheck disable=SC2086
FIXED_FONTS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -E '\.font\(\s*\.system\(size:\s*[0-9]' "$PROJECT_DIR" 2>/dev/null || true)

FIXED_FONT_COUNT=0
if [[ -n "$FIXED_FONTS" ]]; then
    FIXED_FONT_COUNT=$(echo "$FIXED_FONTS" | wc -l | xargs)
fi

# Check for proper text styles (positive signal)
# shellcheck disable=SC2086
DYNAMIC_FONTS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.font\(\s*\.(largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)\b' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Fixed-size fonts: $FIXED_FONT_COUNT, Dynamic Type fonts: $DYNAMIC_FONTS" >&2

if [[ "$FIXED_FONT_COUNT" -gt 5 ]]; then
    PENALTY=$(( (FIXED_FONT_COUNT - 5) / 5 ))
    if [[ "$PENALTY" -gt 0 ]]; then
        ISSUES=$((ISSUES + PENALTY))
        DETAILS="${DETAILS}\n[FIXED_FONT_SIZE] $FIXED_FONT_COUNT hardcoded font sizes (use Dynamic Type text styles) (-1 per 5 over 5)"
    fi
fi

# ---------------------------------------------------------------------------
# 4. VoiceOver compatibility — check for accessibilityElement markers
# ---------------------------------------------------------------------------
echo "Checking: VoiceOver compatibility..." >&2

# shellcheck disable=SC2086
A11Y_ELEMENTS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.accessibilityElement\(|\.accessibilityLabel\(|\.accessibilityHint\(|\.accessibilityValue\(|\.accessibilityAction\(' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Accessibility modifiers: $A11Y_ELEMENTS" >&2

# If there are many SwiftUI views but very few accessibility annotations
if [[ "$SWIFTUI_COUNT" -gt 5 ]] && [[ "$A11Y_ELEMENTS" -lt 3 ]]; then
    ISSUES=$((ISSUES + 2))
    DETAILS="${DETAILS}\n[LOW_A11Y_COVERAGE] Only $A11Y_ELEMENTS accessibility modifier(s) across $SWIFTUI_COUNT views — needs more VoiceOver support (-2)"
fi

# ---------------------------------------------------------------------------
# 5. Color contrast — check for use of semantic/adaptive colors
# ---------------------------------------------------------------------------
echo "Checking: Adaptive colors..." >&2

# shellcheck disable=SC2086
HARDCODED_COLORS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'Color\(\s*red:|UIColor\(\s*red:|\.white\b|\.black\b' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

# shellcheck disable=SC2086
SEMANTIC_COLORS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'Color\(\s*"[^"]*"|\.primary\b|\.secondary\b|\.accentColor|Color\.label|Color\.systemBackground' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Hardcoded colors: $HARDCODED_COLORS, Semantic/adaptive colors: $SEMANTIC_COLORS" >&2

if [[ "$HARDCODED_COLORS" -gt 10 ]] && [[ "$SEMANTIC_COLORS" -lt "$HARDCODED_COLORS" ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[HARDCODED_COLORS] $HARDCODED_COLORS hardcoded color(s) vs $SEMANTIC_COLORS semantic — may affect Dark Mode/contrast (-1)"
fi

# ---------------------------------------------------------------------------
# 6. Navigation — check for NavigationStack/NavigationView usage
# ---------------------------------------------------------------------------
echo "Checking: Navigation patterns..." >&2

# shellcheck disable=SC2086
NAV_DEPRECATED=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'NavigationView\s*\{' "$PROJECT_DIR" 2>/dev/null \
    | awk -F: '{s+=$2} END {print s+0}')

if [[ "$NAV_DEPRECATED" -gt 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[DEPRECATED_NAV] $NAV_DEPRECATED use(s) of NavigationView (deprecated — use NavigationStack) (-1)"
fi

echo "  Deprecated NavigationView: $NAV_DEPRECATED" >&2

# ---------------------------------------------------------------------------
# 7. Check for .accessibilityAddTraits / .accessibilityRemoveTraits
# ---------------------------------------------------------------------------
# shellcheck disable=SC2086
TRAITS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.accessibilityAddTraits|\.accessibilityRemoveTraits' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Accessibility traits modifiers: $TRAITS" >&2

# ---------------------------------------------------------------------------
# 8. Haptic feedback — interactive elements should have haptics
# ---------------------------------------------------------------------------
echo "Checking: Haptic feedback..." >&2

# shellcheck disable=SC2086
HAPTIC_CALLS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'AppHaptics\.|\.sensoryFeedback\(|UIImpactFeedbackGenerator|UINotificationFeedbackGenerator' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

# shellcheck disable=SC2086
BUTTON_COUNT=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE 'Button\s*(\(|{)|PremiumButton' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Haptic calls: $HAPTIC_CALLS, Buttons: $BUTTON_COUNT" >&2

if [[ "$BUTTON_COUNT" -gt 5 ]] && [[ "$HAPTIC_CALLS" -eq 0 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[NO_HAPTICS] $BUTTON_COUNT buttons but zero haptic feedback — add AppHaptics or .sensoryFeedback() (-1)"
fi

# ---------------------------------------------------------------------------
# 9. Animations and transitions
# ---------------------------------------------------------------------------
echo "Checking: Animations and transitions..." >&2

# shellcheck disable=SC2086
ANIMATION_CALLS=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.animation\(|withAnimation|\.transition\(|\.symbolEffect\(|\.contentTransition\(' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Animation/transition calls: $ANIMATION_CALLS" >&2

if [[ "$SWIFTUI_COUNT" -gt 5 ]] && [[ "$ANIMATION_CALLS" -lt 3 ]]; then
    ISSUES=$((ISSUES + 1))
    DETAILS="${DETAILS}\n[LOW_ANIMATIONS] Only $ANIMATION_CALLS animation(s) across $SWIFTUI_COUNT views — add transitions and symbol effects (-1)"
fi

# ---------------------------------------------------------------------------
# 10. Material/glassmorphism usage
# ---------------------------------------------------------------------------
echo "Checking: Material usage..." >&2

# shellcheck disable=SC2086
MATERIAL_USAGE=$(grep -rn --include="*.swift" $EXCLUDE_DIRS \
    -cE '\.thinMaterial|\.ultraThinMaterial|\.regularMaterial|\.thickMaterial' \
    "$PROJECT_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

echo "  Material/glass effects: $MATERIAL_USAGE" >&2

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "" >&2
if [[ -n "$DETAILS" ]]; then
    echo -e "UX/Accessibility issues found:" >&2
    echo -e "$DETAILS" >&2
fi

echo "" >&2
echo "Total UX deductions: $ISSUES" >&2

# Score: 10 minus deductions, minimum 0
SCORE=$((10 - ISSUES))
if [[ "$SCORE" -lt 0 ]]; then
    SCORE=0
fi

echo "UX review score: $SCORE" >&2
echo "$SCORE"
exit 0
