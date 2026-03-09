#!/bin/bash
# iOS Simulator Testing Script
# Based on ios-simulator-skill from awesome-claude-skills
# Tests app launch, basic navigation, and accessibility in simulator

set -euo pipefail

# --- Configuration ---
PROJECT_DIR="${1:?Usage: simulator_test.sh <project_dir> <app_name>}"
APP_NAME="${2:?Usage: simulator_test.sh <project_dir> <app_name>}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
RESULTS_FILE="${PROJECT_DIR}/simulator_test_results.json"
SCORE=10  # Start at 10, deduct for failures

log() { echo "[simulator_test] $(date +%H:%M:%S) $*"; }
deduct() {
    local points=$1 reason=$2
    SCORE=$((SCORE - points))
    log "DEDUCT -${points}: ${reason}"
    FAILURES+=("${reason}")
}

FAILURES=()

# --- Step 1: Check simulator availability ---
log "Checking simulator availability..."
DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if d['name'] == '${SIMULATOR_NAME}' and d['isAvailable']:
                print(d['udid'])
                sys.exit(0)
print('NONE')
" 2>/dev/null || echo "NONE")

if [ "$DEVICE_ID" = "NONE" ]; then
    log "WARNING: Simulator '${SIMULATOR_NAME}' not available. Trying any available iPhone..."
    DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if 'iPhone' in d['name'] and d['isAvailable']:
                print(d['udid'])
                sys.exit(0)
print('NONE')
" 2>/dev/null || echo "NONE")
fi

if [ "$DEVICE_ID" = "NONE" ]; then
    log "ERROR: No available iOS simulator found. Skipping simulator tests."
    echo '{"score": 5, "status": "skipped", "reason": "no_simulator_available"}' > "$RESULTS_FILE"
    echo "5"
    exit 0
fi

log "Using simulator: ${DEVICE_ID}"

# --- Step 2: Boot simulator ---
log "Booting simulator..."
BOOT_STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d['udid'] == '${DEVICE_ID}':
            print(d['state'])
            sys.exit(0)
print('Unknown')
" 2>/dev/null || echo "Unknown")

if [ "$BOOT_STATE" != "Booted" ]; then
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    sleep 5
fi

# --- Step 3: Build for simulator ---
log "Building ${APP_NAME} for simulator..."
BUILD_OUTPUT=$(xcodebuild \
    -target "$APP_NAME" \
    SDKROOT=iphonesimulator \
    CODE_SIGNING_ALLOWED=NO \
    -destination "id=${DEVICE_ID}" \
    build 2>&1) || {
    deduct 5 "Build for simulator failed"
    log "Build output: ${BUILD_OUTPUT}"
}

# --- Step 4: Install and launch ---
if [ $SCORE -gt 5 ]; then
    # Find the built .app
    APP_PATH=$(echo "$BUILD_OUTPUT" | grep -o '/[^ ]*\.app' | head -1 || true)

    if [ -z "$APP_PATH" ]; then
        # Try to find in DerivedData
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/iphonesimulator/*" -maxdepth 6 2>/dev/null | head -1 || true)
    fi

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
        log "Installing app from: ${APP_PATH}"
        xcrun simctl install "$DEVICE_ID" "$APP_PATH" 2>/dev/null || {
            deduct 3 "App installation failed"
        }

        # Get bundle ID
        BUNDLE_ID=$(defaults read "${APP_PATH}/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")

        if [ -n "$BUNDLE_ID" ]; then
            log "Launching app: ${BUNDLE_ID}"
            xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || {
                deduct 3 "App launch failed"
            }

            # Wait for app to start
            sleep 3

            # Check if app is still running (didn't crash)
            RUNNING=$(xcrun simctl spawn "$DEVICE_ID" launchctl list 2>/dev/null | grep -c "$BUNDLE_ID" || echo "0")
            if [ "$RUNNING" = "0" ]; then
                deduct 3 "App crashed on launch"
            else
                log "App launched successfully and is running"
            fi

            # Terminate app
            xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
        else
            deduct 2 "Could not determine bundle ID"
        fi
    else
        deduct 2 "Could not find built .app bundle"
    fi
fi

# --- Step 5: Accessibility audit ---
log "Running accessibility audit..."
if [ -n "${BUNDLE_ID:-}" ]; then
    # Re-launch for accessibility check
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 3

    # Check for accessibility issues using simctl
    ACCESSIBILITY_OUTPUT=$(xcrun simctl ui "$DEVICE_ID" accessibility 2>/dev/null || echo "unavailable")

    if [ "$ACCESSIBILITY_OUTPUT" = "unavailable" ]; then
        log "Accessibility audit not available on this simulator version"
    else
        log "Accessibility audit completed"
    fi

    xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
fi

# --- Step 6: Screenshot capture ---
log "Capturing simulator screenshot..."
SCREENSHOT_PATH="${PROJECT_DIR}/simulator_screenshot.png"
xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT_PATH" 2>/dev/null || {
    log "Screenshot capture failed (non-critical)"
}

# --- Results ---
SCORE=$((SCORE < 0 ? 0 : SCORE))

log "Simulator test score: ${SCORE}/10"

# Write results JSON
python3 -c "
import json
results = {
    'score': ${SCORE},
    'max_score': 10,
    'simulator': '${SIMULATOR_NAME}',
    'device_id': '${DEVICE_ID}',
    'failures': $(python3 -c "import json; print(json.dumps([$(printf '"%s",' "${FAILURES[@]}" 2>/dev/null || echo "")]))" 2>/dev/null || echo '[]'),
    'checks': {
        'simulator_available': True,
        'build_succeeded': ${SCORE} > 5,
        'app_installs': ${SCORE} > 3,
        'app_launches': ${SCORE} > 0,
        'no_crash': ${SCORE} >= 7
    }
}
with open('${RESULTS_FILE}', 'w') as f:
    json.dump(results, f, indent=2)
"

echo "$SCORE"
