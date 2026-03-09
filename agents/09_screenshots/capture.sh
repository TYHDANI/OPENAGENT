#!/usr/bin/env bash
# Screenshot capture automation for App Store submissions
# Usage: capture.sh <project_dir> [scheme_name]
#
# Captures screenshots on iPhone 15 Pro Max (6.7") and iPad Pro 12.9"

set -euo pipefail

PROJECT_DIR="${1:?Usage: capture.sh <project_dir> [scheme_name]}"
SCHEME="${2:-}"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"

# Device configurations for App Store
declare -A DEVICES=(
  ["iphone_6.7"]="iPhone 15 Pro Max"
  ["ipad_12.9"]="iPad Pro (12.9-inch) (6th generation)"
)

# ── Helpers ──────────────────────────────────────────────────────

setup_dirs() {
  for device_key in "${!DEVICES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$device_key"
  done
}

detect_scheme() {
  if [ -n "$SCHEME" ]; then
    return
  fi

  if [ -f "$PROJECT_DIR/Package.swift" ]; then
    SCHEME=$(grep -oE 'name:\s*"[^"]*"' "$PROJECT_DIR/Package.swift" | head -1 | grep -oE '"[^"]*"' | tr -d '"')
  fi

  for proj in "$PROJECT_DIR"/*.xcodeproj; do
    [ -d "$proj" ] || continue
    SCHEME=$(xcodebuild -project "$proj" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    break
  done

  for ws in "$PROJECT_DIR"/*.xcworkspace; do
    [ -d "$ws" ] || continue
    SCHEME=$(xcodebuild -workspace "$ws" -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | head -1 | xargs)
    break
  done

  if [ -z "$SCHEME" ]; then
    echo "[capture] ERROR: Could not detect scheme. Pass it as second argument."
    exit 1
  fi
  echo "[capture] Detected scheme: $SCHEME"
}

boot_simulator() {
  local device_name="$1"
  local udid

  udid=$(xcrun simctl list devices available -j \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime: continue
    for d in devices:
        if d['name'] == '$device_name' and d['isAvailable']:
            print(d['udid'])
            sys.exit(0)
print('')
" 2>/dev/null)

  if [ -z "$udid" ]; then
    echo "[capture] WARNING: Simulator '$device_name' not found. Skipping."
    return 1
  fi

  echo "[capture] Booting simulator: $device_name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  echo "$udid"
}

capture_screenshot() {
  local udid="$1"
  local output_path="$2"

  xcrun simctl io "$udid" screenshot "$output_path" 2>/dev/null
  echo "[capture] Saved: $output_path"
}

shutdown_simulator() {
  local udid="$1"
  xcrun simctl shutdown "$udid" 2>/dev/null || true
}

# ── Main ─────────────────────────────────────────────────────────

main() {
  echo "[capture] Starting screenshot capture for: $PROJECT_DIR"

  setup_dirs
  detect_scheme

  for device_key in "${!DEVICES[@]}"; do
    local device_name="${DEVICES[$device_key]}"
    echo "[capture] Processing device: $device_name"

    local udid
    udid=$(boot_simulator "$device_name") || continue

    # Wait for simulator to be ready
    sleep 3

    # Build and install the app
    echo "[capture] Building for $device_name..."
    if xcodebuild -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -derivedDataPath "$PROJECT_DIR/DerivedData" \
        build 2>/dev/null; then

      # Find and install the .app
      local app_path
      app_path=$(find "$PROJECT_DIR/DerivedData" -name "*.app" -type d | head -1)

      if [ -n "$app_path" ]; then
        xcrun simctl install "$udid" "$app_path" 2>/dev/null || true

        # Get bundle ID
        local bundle_id
        bundle_id=$(defaults read "$app_path/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")

        if [ -n "$bundle_id" ]; then
          xcrun simctl launch "$udid" "$bundle_id" 2>/dev/null || true
          sleep 2

          # Capture screenshots at different states
          for i in $(seq 1 5); do
            capture_screenshot "$udid" "$SCREENSHOTS_DIR/$device_key/screenshot_${i}.png"
            sleep 1
          done
        fi
      fi
    else
      echo "[capture] WARNING: Build failed for $device_name"
    fi

    shutdown_simulator "$udid"
  done

  echo "[capture] Screenshot capture complete."
  echo "[capture] Screenshots saved to: $SCREENSHOTS_DIR"
  ls -la "$SCREENSHOTS_DIR"/*/ 2>/dev/null || true
}

main "$@"
