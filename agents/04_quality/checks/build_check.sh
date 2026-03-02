#!/usr/bin/env bash
set -euo pipefail

# build_check.sh — Build verification for iOS/Swift projects
# Usage: build_check.sh <project_dir>
# Outputs: score 0-10 on stdout
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: build_check.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

# Detect the scheme name from the Xcode project
SCHEME=""
if ls *.xcworkspace 1>/dev/null 2>&1; then
    WORKSPACE=$(ls -1 *.xcworkspace | head -1)
    SCHEME=$(xcodebuild -workspace "$WORKSPACE" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    BUILD_FLAG="-workspace $WORKSPACE"
    echo "Detected workspace: $WORKSPACE" >&2
elif ls *.xcodeproj 1>/dev/null 2>&1; then
    XCODEPROJ=$(ls -1 *.xcodeproj | head -1)
    SCHEME=$(xcodebuild -project "$XCODEPROJ" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    BUILD_FLAG="-project $XCODEPROJ"
    echo "Detected project: $XCODEPROJ" >&2
elif [[ -f "Package.swift" ]]; then
    # Swift Package — use swift build instead
    echo "Detected Swift Package (Package.swift)" >&2
    BUILD_OUTPUT=$(swift build 2>&1) || true
    ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "error:" 2>/dev/null || echo "0")
    WARNINGS=$(echo "$BUILD_OUTPUT" | grep -c "warning:" 2>/dev/null || echo "0")

    echo "Swift build: errors=$ERRORS, warnings=$WARNINGS" >&2

    if [[ "$ERRORS" -gt 0 ]]; then
        echo "Build FAILED with $ERRORS error(s)" >&2
        echo 0
        exit 0
    elif [[ "$WARNINGS" -gt 0 ]]; then
        echo "Build succeeded with $WARNINGS warning(s)" >&2
        echo 5
        exit 0
    else
        echo "Build succeeded cleanly" >&2
        echo 10
        exit 0
    fi
else
    echo "ERROR: No .xcworkspace, .xcodeproj, or Package.swift found in $PROJECT_DIR" >&2
    exit 1
fi

if [[ -z "$SCHEME" ]]; then
    echo "ERROR: Could not detect scheme from Xcode project" >&2
    exit 1
fi

echo "Using scheme: $SCHEME" >&2

# Run xcodebuild clean build
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
BUILD_LOG=$(mktemp /tmp/build_check.XXXXXX.log)
trap "rm -f '$BUILD_LOG'" EXIT

echo "Running: xcodebuild $BUILD_FLAG -scheme '$SCHEME' -destination '$DESTINATION' clean build" >&2

# shellcheck disable=SC2086
xcodebuild $BUILD_FLAG \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    clean build \
    2>&1 | tee "$BUILD_LOG" >&2 || true

# Analyze results
BUILD_SUCCEEDED=$(grep -c "BUILD SUCCEEDED" "$BUILD_LOG" 2>/dev/null || echo "0")
BUILD_FAILED=$(grep -c "BUILD FAILED" "$BUILD_LOG" 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "warning:" "$BUILD_LOG" 2>/dev/null || echo "0")
ERROR_COUNT=$(grep -c "error:" "$BUILD_LOG" 2>/dev/null || echo "0")

echo "Build results: succeeded=$BUILD_SUCCEEDED, failed=$BUILD_FAILED, warnings=$WARNING_COUNT, errors=$ERROR_COUNT" >&2

if [[ "$BUILD_FAILED" -gt 0 ]] || [[ "$ERROR_COUNT" -gt 0 ]]; then
    echo "Build FAILED" >&2
    echo 0
elif [[ "$WARNING_COUNT" -gt 0 ]]; then
    echo "Build succeeded with $WARNING_COUNT warning(s)" >&2
    echo 5
elif [[ "$BUILD_SUCCEEDED" -gt 0 ]]; then
    echo "Build succeeded cleanly" >&2
    echo 10
else
    echo "Build result unclear — assuming failure" >&2
    echo 0
fi

exit 0
