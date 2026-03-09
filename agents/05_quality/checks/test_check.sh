#!/usr/bin/env bash
set -euo pipefail

# test_check.sh — Test runner for iOS/Swift projects
# Usage: test_check.sh <project_dir>
# Outputs: score 0-10 on stdout (deduct 2 per failure, minimum 0)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: test_check.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

TEST_LOG=$(mktemp /tmp/test_check.XXXXXX.log)
trap "rm -f '$TEST_LOG'" EXIT

# Determine project type and run tests
if [[ -f "Package.swift" ]]; then
    echo "Running: swift test" >&2
    swift test 2>&1 | tee "$TEST_LOG" >&2 || true

    # Parse swift test output
    TOTAL_TESTS=$(grep -cE "Test Case.*started" "$TEST_LOG" 2>/dev/null || echo "0")
    PASSED=$(grep -cE "Test Case.*passed" "$TEST_LOG" 2>/dev/null || echo "0")
    FAILED=$(grep -cE "Test Case.*failed" "$TEST_LOG" 2>/dev/null || echo "0")

elif ls *.xcworkspace 1>/dev/null 2>&1; then
    WORKSPACE=$(ls -1 *.xcworkspace | head -1)
    SCHEME=$(xcodebuild -workspace "$WORKSPACE" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"

    echo "Running: xcodebuild test -workspace $WORKSPACE -scheme $SCHEME" >&2
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -resultBundlePath /tmp/test_results.xcresult \
        2>&1 | tee "$TEST_LOG" >&2 || true

    TOTAL_TESTS=$(grep -cE "Test Case.*started" "$TEST_LOG" 2>/dev/null || echo "0")
    PASSED=$(grep -cE "Test Case.*passed" "$TEST_LOG" 2>/dev/null || echo "0")
    FAILED=$(grep -cE "Test Case.*failed" "$TEST_LOG" 2>/dev/null || echo "0")

elif ls *.xcodeproj 1>/dev/null 2>&1; then
    XCODEPROJ=$(ls -1 *.xcodeproj | head -1)
    SCHEME=$(xcodebuild -project "$XCODEPROJ" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"

    echo "Running: xcodebuild test -project $XCODEPROJ -scheme $SCHEME" >&2
    xcodebuild test \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -resultBundlePath /tmp/test_results.xcresult \
        2>&1 | tee "$TEST_LOG" >&2 || true

    TOTAL_TESTS=$(grep -cE "Test Case.*started" "$TEST_LOG" 2>/dev/null || echo "0")
    PASSED=$(grep -cE "Test Case.*passed" "$TEST_LOG" 2>/dev/null || echo "0")
    FAILED=$(grep -cE "Test Case.*failed" "$TEST_LOG" 2>/dev/null || echo "0")

else
    echo "ERROR: No testable project found (no Package.swift, .xcworkspace, or .xcodeproj)" >&2
    exit 1
fi

echo "Test results: total=$TOTAL_TESTS, passed=$PASSED, failed=$FAILED" >&2

# If no tests were found at all, report it but don't fail
if [[ "$TOTAL_TESTS" -eq 0 ]]; then
    echo "WARNING: No tests found in project" >&2
    # Give a 5 — project builds but has no tests
    echo 5
    exit 0
fi

# Score: 10 if all pass, deduct 2 per failure, minimum 0
SCORE=$((10 - FAILED * 2))
if [[ "$SCORE" -lt 0 ]]; then
    SCORE=0
fi

echo "Test score: $SCORE (${FAILED} failure(s) out of ${TOTAL_TESTS} test(s))" >&2
echo "$SCORE"
exit 0
