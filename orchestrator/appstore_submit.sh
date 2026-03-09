#!/usr/bin/env bash
# OPENAGENT — Automated App Store Submission
# Archives, exports IPA, uploads to App Store Connect, distributes via TestFlight
#
# Usage: bash appstore_submit.sh <project_dir> <action>
# Actions: archive | upload | testflight | status | full-submit
#
# Prerequisites:
#   - App Store Connect API Key (.p8) at ~/.appstore/AuthKey_XXXX.p8
#   - ASC_KEY_ID, ASC_ISSUER_ID, TEAM_ID in ~/.env.openagent
#   - Xcode with valid signing certificates installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
ENV_FILE="$HOME/.env.openagent"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

PROJECT_DIR="${1:?Usage: appstore_submit.sh <project_dir> <action>}"
ACTION="${2:-full-submit}"

# ── Read project state ────────────────────────────────────────────
STATE_FILE="$PROJECT_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  echo "[appstore_submit] ERROR: No state.json found in $PROJECT_DIR"
  exit 1
fi

APP_NAME=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('name','unknown'))" 2>/dev/null)
BUNDLE_ID=$(python3 -c "
import json, glob, re
# Try state.json first
s = json.load(open('$STATE_FILE'))
bid = s.get('bundle_id', '')
if bid:
    print(bid)
else:
    # Try to extract from Package.swift or xcodeproj
    pkg = '$PROJECT_DIR/Package.swift'
    try:
        with open(pkg) as f:
            content = f.read()
        m = re.search(r'bundleIdentifier.*?\"(.+?)\"', content)
        if m:
            print(m.group(1))
        else:
            # Default pattern
            print('com.openagent.' + '$APP_NAME'.lower().replace(' ', ''))
    except:
        print('com.openagent.' + '$APP_NAME'.lower().replace(' ', ''))
" 2>/dev/null)

echo "[appstore_submit] App: $APP_NAME | Bundle ID: $BUNDLE_ID"

# ── Validate credentials ─────────────────────────────────────────
validate_credentials() {
  local missing=0

  if [ -z "${ASC_KEY_ID:-}" ]; then
    echo "[appstore_submit] ERROR: ASC_KEY_ID not set in ~/.env.openagent"
    missing=1
  fi

  if [ -z "${ASC_ISSUER_ID:-}" ]; then
    echo "[appstore_submit] ERROR: ASC_ISSUER_ID not set in ~/.env.openagent"
    missing=1
  fi

  if [ -z "${TEAM_ID:-}" ]; then
    echo "[appstore_submit] ERROR: TEAM_ID not set in ~/.env.openagent"
    missing=1
  fi

  # Find the .p8 key file
  ASC_KEY_FILE=""
  if [ -d "$HOME/.appstore" ]; then
    ASC_KEY_FILE=$(find "$HOME/.appstore" -name "AuthKey_*.p8" -type f 2>/dev/null | head -1)
  fi
  if [ -z "$ASC_KEY_FILE" ] && [ -d "$HOME/.private_keys" ]; then
    ASC_KEY_FILE=$(find "$HOME/.private_keys" -name "AuthKey_*.p8" -type f 2>/dev/null | head -1)
  fi

  if [ -z "$ASC_KEY_FILE" ]; then
    echo "[appstore_submit] ERROR: No AuthKey_*.p8 found in ~/.appstore/ or ~/.private_keys/"
    echo "[appstore_submit] Download from: App Store Connect > Users and Access > Integrations > Keys"
    missing=1
  else
    echo "[appstore_submit] Using API key: $ASC_KEY_FILE"
  fi

  if [ "$missing" -eq 1 ]; then
    echo ""
    echo "=== SETUP REQUIRED ==="
    echo "Add these to ~/.env.openagent:"
    echo "  ASC_KEY_ID=YOUR_KEY_ID"
    echo "  ASC_ISSUER_ID=YOUR_ISSUER_ID"
    echo "  TEAM_ID=YOUR_TEAM_ID"
    echo ""
    echo "Place your .p8 key file at:"
    echo "  ~/.appstore/AuthKey_YOURKEYID.p8"
    echo ""
    echo "Get these from:"
    echo "  1. https://appstoreconnect.apple.com/access/integrations/api (Key ID + Issuer ID)"
    echo "  2. https://developer.apple.com/account (Team ID under Membership)"
    return 1
  fi

  return 0
}

# ── Resolve Xcode project/workspace ──────────────────────────────
find_xcode_project() {
  local proj_dir="$1"

  # Priority: .xcworkspace > .xcodeproj > Package.swift (SPM)
  local workspace=$(find "$proj_dir" -maxdepth 2 -name "*.xcworkspace" -not -path "*/.*" 2>/dev/null | head -1)
  local xcodeproj=$(find "$proj_dir" -maxdepth 2 -name "*.xcodeproj" -not -path "*/.*" 2>/dev/null | head -1)
  local package_swift="$proj_dir/Package.swift"

  if [ -n "$workspace" ]; then
    echo "workspace:$workspace"
  elif [ -n "$xcodeproj" ]; then
    echo "project:$xcodeproj"
  elif [ -f "$package_swift" ]; then
    echo "spm:$package_swift"
  else
    echo "none"
  fi
}

# ── Generate ExportOptions.plist ─────────────────────────────────
generate_export_options() {
  local export_plist="$PROJECT_DIR/ExportOptions.plist"
  local method="${1:-app-store}"  # app-store | ad-hoc | development

  cat > "$export_plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${method}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>upload</string>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
PLIST_EOF

  echo "[appstore_submit] Generated ExportOptions.plist (method: $method)"
}

# ── Resolve scheme name ──────────────────────────────────────────
get_scheme() {
  local project_type="$1"
  local project_path="$2"

  case "$project_type" in
    workspace:*)
      # List schemes from workspace
      xcodebuild -workspace "${project_path}" -list 2>/dev/null | \
        grep -A 100 "Schemes:" | grep -v "Schemes:" | head -1 | xargs
      ;;
    project:*)
      xcodebuild -project "${project_path}" -list 2>/dev/null | \
        grep -A 100 "Schemes:" | grep -v "Schemes:" | head -1 | xargs
      ;;
    spm:*)
      # SPM: scheme = product name, usually the app name
      echo "$APP_NAME"
      ;;
  esac
}

# ── Generate Xcode project from SPM if needed ───────────────────
ensure_xcode_project() {
  local proj_info=$(find_xcode_project "$PROJECT_DIR")

  if [[ "$proj_info" == spm:* ]]; then
    echo "[appstore_submit] SPM project detected — generating .xcodeproj..."

    # Check if there's an existing Sources directory structure
    if [ -d "$PROJECT_DIR/Sources" ]; then
      cd "$PROJECT_DIR"

      # Generate xcodeproj from Package.swift
      swift package generate-xcodeproj 2>/dev/null || {
        echo "[appstore_submit] swift package generate-xcodeproj failed"
        echo "[appstore_submit] Attempting xcodebuild with SPM directly..."
        # Modern Xcode can build SPM packages directly
        return 0
      }

      cd "$ROOT_DIR"
      proj_info=$(find_xcode_project "$PROJECT_DIR")
    fi
  fi

  echo "$proj_info"
}

# ── Archive the app ──────────────────────────────────────────────
archive_app() {
  echo "[appstore_submit] === ARCHIVING $APP_NAME ==="

  local build_output="${BUILD_OUTPUT_DIR:-/Volumes/T7/OPENAGENT_builds}"
  local archive_path="$build_output/${APP_NAME}.xcarchive"
  local archive_log="$PROJECT_DIR/archive_log.txt"

  mkdir -p "$build_output"

  # Find and prepare project
  local proj_info=$(ensure_xcode_project)
  local proj_type="${proj_info%%:*}"
  local proj_path="${proj_info#*:}"

  if [ "$proj_type" = "none" ]; then
    echo "[appstore_submit] ERROR: No Xcode project, workspace, or Package.swift found"
    return 1
  fi

  # Get scheme
  local scheme=$(get_scheme "$proj_type" "$proj_path")
  if [ -z "$scheme" ]; then
    scheme="$APP_NAME"
  fi

  echo "[appstore_submit] Project type: $proj_type"
  echo "[appstore_submit] Project path: $proj_path"
  echo "[appstore_submit] Scheme: $scheme"
  echo "[appstore_submit] Archive path: $archive_path"

  # Build the archive command
  local xcode_cmd="xcodebuild archive"
  xcode_cmd+=" -scheme \"$scheme\""

  case "$proj_type" in
    workspace)
      xcode_cmd+=" -workspace \"$proj_path\""
      ;;
    project)
      xcode_cmd+=" -project \"$proj_path\""
      ;;
    spm)
      # For SPM, we work from the project directory
      xcode_cmd+=" -packagePath \"$PROJECT_DIR\""
      ;;
  esac

  xcode_cmd+=" -destination 'generic/platform=iOS'"
  xcode_cmd+=" -archivePath \"$archive_path\""
  xcode_cmd+=" DEVELOPMENT_TEAM=\"$TEAM_ID\""
  xcode_cmd+=" CODE_SIGN_STYLE=Automatic"
  xcode_cmd+=" -allowProvisioningUpdates"
  xcode_cmd+=" -authenticationKeyPath \"$ASC_KEY_FILE\""
  xcode_cmd+=" -authenticationKeyID \"$ASC_KEY_ID\""
  xcode_cmd+=" -authenticationKeyIssuerID \"$ASC_ISSUER_ID\""

  echo "[appstore_submit] Running: xcodebuild archive..."
  eval "$xcode_cmd" 2>&1 | tee "$archive_log"

  local exit_code=${PIPESTATUS[0]}

  if [ "$exit_code" -ne 0 ]; then
    echo "[appstore_submit] ERROR: Archive failed (exit code: $exit_code)"
    echo "[appstore_submit] See log: $archive_log"

    # Try to extract the key error
    local error_summary=$(grep -E "(error:|fatal error:)" "$archive_log" | head -5)
    if [ -n "$error_summary" ]; then
      echo "[appstore_submit] Key errors:"
      echo "$error_summary"
    fi

    return 1
  fi

  if [ ! -d "$archive_path" ]; then
    echo "[appstore_submit] ERROR: Archive not created at $archive_path"
    return 1
  fi

  echo "[appstore_submit] Archive created: $archive_path"

  # Update state.json
  python3 -c "
import json
with open('$STATE_FILE') as f:
    state = json.load(f)
state['archive_path'] = '$archive_path'
state['archive_date'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null

  return 0
}

# ── Export IPA from archive ──────────────────────────────────────
export_ipa() {
  echo "[appstore_submit] === EXPORTING IPA ==="

  local build_output="${BUILD_OUTPUT_DIR:-/Volumes/T7/OPENAGENT_builds}"
  local archive_path="$build_output/${APP_NAME}.xcarchive"
  local export_path="$build_output/${APP_NAME}_export"
  local export_log="$PROJECT_DIR/export_log.txt"

  if [ ! -d "$archive_path" ]; then
    echo "[appstore_submit] ERROR: No archive found at $archive_path — run 'archive' first"
    return 1
  fi

  # Generate ExportOptions.plist
  generate_export_options "app-store"

  mkdir -p "$export_path"

  xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_FILE" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    2>&1 | tee "$export_log"

  local exit_code=${PIPESTATUS[0]}

  if [ "$exit_code" -ne 0 ]; then
    echo "[appstore_submit] ERROR: Export failed (exit code: $exit_code)"
    return 1
  fi

  # Find the IPA
  local ipa_file=$(find "$export_path" -name "*.ipa" -type f 2>/dev/null | head -1)
  if [ -z "$ipa_file" ]; then
    echo "[appstore_submit] ERROR: No IPA found in export directory"
    return 1
  fi

  echo "[appstore_submit] IPA exported: $ipa_file"

  # Update state.json
  python3 -c "
import json
with open('$STATE_FILE') as f:
    state = json.load(f)
state['ipa_path'] = '$ipa_file'
state['export_date'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null

  return 0
}

# ── Upload to App Store Connect ──────────────────────────────────
upload_to_appstore() {
  echo "[appstore_submit] === UPLOADING TO APP STORE CONNECT ==="

  local build_output="${BUILD_OUTPUT_DIR:-/Volumes/T7/OPENAGENT_builds}"
  local export_path="$build_output/${APP_NAME}_export"

  # Find IPA
  local ipa_file=$(find "$export_path" -name "*.ipa" -type f 2>/dev/null | head -1)
  if [ -z "$ipa_file" ]; then
    echo "[appstore_submit] ERROR: No IPA found — run 'archive' and 'export' first"
    return 1
  fi

  echo "[appstore_submit] Uploading: $ipa_file"

  # Use xcrun notarytool for modern upload (Xcode 14+)
  # Or xcrun altool for older compatibility
  if xcrun --find notarytool &>/dev/null; then
    echo "[appstore_submit] Using xcrun altool for App Store upload..."
  fi

  # Upload via altool (works for App Store submissions)
  xcrun altool --upload-app \
    --type ios \
    --file "$ipa_file" \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" \
    2>&1 | tee "$PROJECT_DIR/upload_log.txt"

  local exit_code=${PIPESTATUS[0]}

  if [ "$exit_code" -ne 0 ]; then
    echo "[appstore_submit] ERROR: Upload failed"

    # Check for common errors
    if grep -q "Unable to authenticate" "$PROJECT_DIR/upload_log.txt"; then
      echo "[appstore_submit] HINT: Check ASC_KEY_ID and ASC_ISSUER_ID in ~/.env.openagent"
      echo "[appstore_submit] HINT: Ensure AuthKey_*.p8 is in ~/.appstore/ or ~/.private_keys/"
    elif grep -q "No suitable application records" "$PROJECT_DIR/upload_log.txt"; then
      echo "[appstore_submit] HINT: Create the app record first in App Store Connect"
      echo "[appstore_submit] Running: create_app_record..."
      create_app_record
    elif grep -q "already been uploaded" "$PROJECT_DIR/upload_log.txt"; then
      echo "[appstore_submit] Build already uploaded — increment build number and retry"
    fi

    return 1
  fi

  echo "[appstore_submit] Upload successful!"

  # Update state.json
  python3 -c "
import json
from datetime import datetime, timezone
with open('$STATE_FILE') as f:
    state = json.load(f)
state['uploaded_to_appstore'] = True
state['upload_date'] = datetime.now(timezone.utc).isoformat()
state['submission_status'] = 'processing'
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null

  # Log to launches.jsonl
  python3 -c "
import json
from datetime import datetime, timezone
entry = {
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'app': '$APP_NAME',
    'bundle_id': '$BUNDLE_ID',
    'action': 'uploaded_to_appstore',
    'ipa': '$ipa_file'
}
with open('$ROOT_DIR/logs/launches.jsonl', 'a') as f:
    f.write(json.dumps(entry) + '\n')
" 2>/dev/null

  return 0
}

# ── Create App Store Connect record via API ──────────────────────
create_app_record() {
  echo "[appstore_submit] Creating app record in App Store Connect..."

  # Read metadata
  local app_metadata="$PROJECT_DIR/appstore_metadata.json"
  if [ ! -f "$app_metadata" ]; then
    echo "[appstore_submit] ERROR: No appstore_metadata.json — run phase 7 first"
    return 1
  fi

  python3 << 'PYTHON_EOF'
import json
import jwt
import time
import os
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

# Load credentials
key_id = os.environ.get('ASC_KEY_ID', '')
issuer_id = os.environ.get('ASC_ISSUER_ID', '')
team_id = os.environ.get('TEAM_ID', '')

# Find .p8 key
key_file = None
for d in [os.path.expanduser('~/.appstore'), os.path.expanduser('~/.private_keys')]:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.startswith('AuthKey_') and f.endswith('.p8'):
                key_file = os.path.join(d, f)
                break

if not key_file:
    print('[appstore_submit] ERROR: No .p8 key file found')
    sys.exit(1)

# Read key
with open(key_file) as f:
    private_key = f.read()

# Generate JWT
now = int(time.time())
payload = {
    'iss': issuer_id,
    'iat': now,
    'exp': now + 1200,  # 20 minutes
    'aud': 'appstoreconnect-v1'
}
token = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': key_id})

# Read app metadata
state_file = os.environ.get('STATE_FILE', 'state.json')
project_dir = os.environ.get('PROJECT_DIR', '.')

with open(f'{project_dir}/appstore_metadata.json') as f:
    metadata = json.load(f)

app_name = metadata.get('app_name', '')
bundle_id_val = os.environ.get('BUNDLE_ID', '')
sku = bundle_id_val.replace('.', '_')
primary_locale = 'en-US'

# Create app record
url = 'https://api.appstoreconnect.apple.com/v1/apps'
body = {
    'data': {
        'type': 'apps',
        'attributes': {
            'name': app_name,
            'bundleId': bundle_id_val,
            'sku': sku,
            'primaryLocale': primary_locale
        }
    }
}

req = Request(url, data=json.dumps(body).encode(), method='POST')
req.add_header('Authorization', f'Bearer {token}')
req.add_header('Content-Type', 'application/json')

try:
    with urlopen(req) as resp:
        result = json.loads(resp.read())
        app_id = result['data']['id']
        print(f'[appstore_submit] App record created! App ID: {app_id}')

        # Save app ID to state
        with open(state_file) as f:
            state = json.load(f)
        state['appstore_connect_id'] = app_id
        with open(state_file, 'w') as f:
            json.dump(state, f, indent=2)

except HTTPError as e:
    error_body = e.read().decode()
    print(f'[appstore_submit] App Store Connect API error ({e.code}): {error_body}')
    if 'ENTITY_ERROR.ATTRIBUTE.INVALID' in error_body:
        print('[appstore_submit] HINT: App name or bundle ID may already be taken')
    elif 'ENTITY_ERROR.RELATIONSHIP.INVALID' in error_body:
        print('[appstore_submit] HINT: Bundle ID not registered — register at developer.apple.com/account/resources/identifiers')
    sys.exit(1)
PYTHON_EOF
}

# ── Distribute to TestFlight ─────────────────────────────────────
distribute_testflight() {
  echo "[appstore_submit] === DISTRIBUTING TO TESTFLIGHT ==="

  # After upload, the build processes automatically.
  # We need to wait for processing, then submit to TestFlight review.

  python3 << 'PYTHON_EOF'
import json
import jwt
import time
import os
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

key_id = os.environ.get('ASC_KEY_ID', '')
issuer_id = os.environ.get('ASC_ISSUER_ID', '')

# Find key
key_file = None
for d in [os.path.expanduser('~/.appstore'), os.path.expanduser('~/.private_keys')]:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.startswith('AuthKey_') and f.endswith('.p8'):
                key_file = os.path.join(d, f)
                break

with open(key_file) as f:
    private_key = f.read()

now = int(time.time())
payload = {'iss': issuer_id, 'iat': now, 'exp': now + 1200, 'aud': 'appstoreconnect-v1'}
token = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': key_id})

bundle_id = os.environ.get('BUNDLE_ID', '')

# Find the app
url = f'https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}'
req = Request(url)
req.add_header('Authorization', f'Bearer {token}')

try:
    with urlopen(req) as resp:
        apps = json.loads(resp.read())

    if not apps['data']:
        print(f'[appstore_submit] No app found with bundle ID: {bundle_id}')
        sys.exit(1)

    app_id = apps['data'][0]['id']

    # Get latest build
    builds_url = f'https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=1'
    req = Request(builds_url)
    req.add_header('Authorization', f'Bearer {token}')

    with urlopen(req) as resp:
        builds = json.loads(resp.read())

    if not builds['data']:
        print('[appstore_submit] No builds found — upload may still be processing')
        print('[appstore_submit] Run "status" in a few minutes to check')
        sys.exit(0)

    build = builds['data'][0]
    build_id = build['id']
    processing_state = build['attributes'].get('processingState', 'UNKNOWN')
    version = build['attributes'].get('version', '?')

    print(f'[appstore_submit] Latest build: v{version} (ID: {build_id})')
    print(f'[appstore_submit] Processing state: {processing_state}')

    if processing_state != 'VALID':
        print(f'[appstore_submit] Build still processing ({processing_state}) — try again later')
        sys.exit(0)

    # Enable TestFlight for this build by adding beta testers group
    # First, submit for beta review
    beta_url = 'https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions'
    body = {
        'data': {
            'type': 'betaAppReviewSubmissions',
            'relationships': {
                'build': {
                    'data': {'type': 'builds', 'id': build_id}
                }
            }
        }
    }

    req = Request(beta_url, data=json.dumps(body).encode(), method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Content-Type', 'application/json')

    with urlopen(req) as resp:
        result = json.loads(resp.read())
        print(f'[appstore_submit] TestFlight beta review submitted for build {version}!')
        print('[appstore_submit] TestFlight link will be available after review (usually <24h)')

except HTTPError as e:
    error_body = e.read().decode()
    if 'ENTITY_ERROR.STATE_ERROR' in error_body:
        print('[appstore_submit] Build already submitted for TestFlight review')
    else:
        print(f'[appstore_submit] API error ({e.code}): {error_body}')
    sys.exit(1)
PYTHON_EOF

  # Update state
  python3 -c "
import json
from datetime import datetime, timezone
with open('$STATE_FILE') as f:
    state = json.load(f)
state['testflight_submitted'] = True
state['testflight_date'] = datetime.now(timezone.utc).isoformat()
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
}

# ── Check submission status ──────────────────────────────────────
check_status() {
  echo "[appstore_submit] === CHECKING STATUS FOR $APP_NAME ==="

  python3 << 'PYTHON_EOF'
import json
import jwt
import time
import os
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

key_id = os.environ.get('ASC_KEY_ID', '')
issuer_id = os.environ.get('ASC_ISSUER_ID', '')

key_file = None
for d in [os.path.expanduser('~/.appstore'), os.path.expanduser('~/.private_keys')]:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.startswith('AuthKey_') and f.endswith('.p8'):
                key_file = os.path.join(d, f)
                break

if not key_file:
    print('[appstore_submit] No .p8 key — cannot check status')
    sys.exit(1)

with open(key_file) as f:
    private_key = f.read()

now = int(time.time())
payload = {'iss': issuer_id, 'iat': now, 'exp': now + 1200, 'aud': 'appstoreconnect-v1'}
token = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': key_id})

bundle_id = os.environ.get('BUNDLE_ID', '')

# Find app
url = f'https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}'
req = Request(url)
req.add_header('Authorization', f'Bearer {token}')

try:
    with urlopen(req) as resp:
        apps = json.loads(resp.read())

    if not apps['data']:
        print(f'[appstore_submit] App not found in App Store Connect: {bundle_id}')
        print('[appstore_submit] You may need to create the app record first')
        sys.exit(0)

    app_id = apps['data'][0]['id']
    app_name = apps['data'][0]['attributes']['name']

    # Get builds
    builds_url = f'https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=3'
    req = Request(builds_url)
    req.add_header('Authorization', f'Bearer {token}')

    with urlopen(req) as resp:
        builds = json.loads(resp.read())

    print(f'\n  App: {app_name} ({bundle_id})')
    print(f'  App Store Connect ID: {app_id}')
    print(f'  Builds:')

    for b in builds['data']:
        attrs = b['attributes']
        print(f"    v{attrs.get('version', '?')} (build {attrs.get('uploadedDate', '?')[:10]})")
        print(f"      Processing: {attrs.get('processingState', '?')}")
        print(f"      Expired: {attrs.get('expired', '?')}")

    # Check app store version status
    versions_url = f'https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions?limit=1'
    req = Request(versions_url)
    req.add_header('Authorization', f'Bearer {token}')

    with urlopen(req) as resp:
        versions = json.loads(resp.read())

    if versions['data']:
        v = versions['data'][0]
        print(f"\n  App Store Version:")
        print(f"    Version: {v['attributes'].get('versionString', '?')}")
        print(f"    State: {v['attributes'].get('appStoreState', '?')}")
        print(f"    Release type: {v['attributes'].get('releaseType', '?')}")
    else:
        print(f"\n  No App Store version created yet")

except HTTPError as e:
    print(f'[appstore_submit] API error ({e.code}): {e.read().decode()[:200]}')
except Exception as e:
    print(f'[appstore_submit] Error: {e}')
PYTHON_EOF
}

# ── Submit metadata to App Store ─────────────────────────────────
submit_metadata() {
  echo "[appstore_submit] === SUBMITTING METADATA ==="

  local metadata_file="$PROJECT_DIR/appstore_metadata.json"
  if [ ! -f "$metadata_file" ]; then
    echo "[appstore_submit] ERROR: No appstore_metadata.json found"
    return 1
  fi

  python3 << 'PYTHON_EOF'
import json
import jwt
import time
import os
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError

key_id = os.environ.get('ASC_KEY_ID', '')
issuer_id = os.environ.get('ASC_ISSUER_ID', '')

key_file = None
for d in [os.path.expanduser('~/.appstore'), os.path.expanduser('~/.private_keys')]:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.startswith('AuthKey_') and f.endswith('.p8'):
                key_file = os.path.join(d, f)
                break

with open(key_file) as f:
    private_key = f.read()

now = int(time.time())
payload = {'iss': issuer_id, 'iat': now, 'exp': now + 1200, 'aud': 'appstoreconnect-v1'}
token = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': key_id})

bundle_id = os.environ.get('BUNDLE_ID', '')
project_dir = os.environ.get('PROJECT_DIR', '.')

# Load metadata
with open(f'{project_dir}/appstore_metadata.json') as f:
    meta = json.load(f)

# Find app
url = f'https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}'
req = Request(url)
req.add_header('Authorization', f'Bearer {token}')

with urlopen(req) as resp:
    apps = json.loads(resp.read())

if not apps['data']:
    print(f'App not found: {bundle_id}')
    sys.exit(1)

app_id = apps['data'][0]['id']

# Get or create app store version
versions_url = f'https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions'
req = Request(versions_url)
req.add_header('Authorization', f'Bearer {token}')

with urlopen(req) as resp:
    versions = json.loads(resp.read())

version_id = None
if versions['data']:
    # Use existing draft version
    for v in versions['data']:
        if v['attributes']['appStoreState'] in ['PREPARE_FOR_SUBMISSION', 'DEVELOPER_ACTION_NEEDED', 'REJECTED']:
            version_id = v['id']
            break

if not version_id:
    # Create new version
    body = {
        'data': {
            'type': 'appStoreVersions',
            'attributes': {
                'platform': 'IOS',
                'versionString': '1.0',
                'releaseType': 'MANUAL'
            },
            'relationships': {
                'app': {'data': {'type': 'apps', 'id': app_id}}
            }
        }
    }
    req = Request(versions_url, data=json.dumps(body).encode(), method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Content-Type', 'application/json')

    with urlopen(req) as resp:
        result = json.loads(resp.read())
        version_id = result['data']['id']
        print(f'Created App Store version 1.0 (ID: {version_id})')

# Update localization (description, keywords, etc.)
loc_url = f'https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations'
req = Request(loc_url)
req.add_header('Authorization', f'Bearer {token}')

with urlopen(req) as resp:
    locs = json.loads(resp.read())

en_loc_id = None
for loc in locs['data']:
    if loc['attributes']['locale'] == 'en-US':
        en_loc_id = loc['id']
        break

if en_loc_id:
    # Update existing localization
    update_url = f'https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{en_loc_id}'
    body = {
        'data': {
            'type': 'appStoreVersionLocalizations',
            'id': en_loc_id,
            'attributes': {
                'description': meta.get('description', '')[:4000],
                'keywords': meta.get('keywords', '')[:100],
                'whatsNew': meta.get('whats_new', 'Initial release.')[:4000],
                'promotionalText': meta.get('promotional_text', '')[:170]
            }
        }
    }
    req = Request(update_url, data=json.dumps(body).encode(), method='PATCH')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Content-Type', 'application/json')

    with urlopen(req) as resp:
        print('Updated en-US localization with metadata')

# Update app info (subtitle, categories)
app_info_url = f'https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appInfos'
req = Request(app_info_url)
req.add_header('Authorization', f'Bearer {token}')

with urlopen(req) as resp:
    infos = json.loads(resp.read())

if infos['data']:
    info_id = infos['data'][0]['id']

    # Update app info localization (subtitle)
    info_loc_url = f'https://api.appstoreconnect.apple.com/v1/appInfos/{info_id}/appInfoLocalizations'
    req = Request(info_loc_url)
    req.add_header('Authorization', f'Bearer {token}')

    with urlopen(req) as resp:
        info_locs = json.loads(resp.read())

    for il in info_locs['data']:
        if il['attributes']['locale'] == 'en-US':
            update_url = f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{il['id']}"
            body = {
                'data': {
                    'type': 'appInfoLocalizations',
                    'id': il['id'],
                    'attributes': {
                        'subtitle': meta.get('subtitle', '')[:30]
                    }
                }
            }
            req = Request(update_url, data=json.dumps(body).encode(), method='PATCH')
            req.add_header('Authorization', f'Bearer {token}')
            req.add_header('Content-Type', 'application/json')

            with urlopen(req) as resp:
                print('Updated subtitle')
            break

print(f'\n[appstore_submit] Metadata submitted for {bundle_id}')
print('[appstore_submit] Next: Upload screenshots manually or via automation')
PYTHON_EOF
}

# ── Full submission pipeline ─────────────────────────────────────
full_submit() {
  echo "[appstore_submit] === FULL SUBMISSION PIPELINE FOR $APP_NAME ==="
  echo ""

  # Step 0: Validate credentials
  if ! validate_credentials; then
    return 1
  fi

  # Step 1: Archive
  echo ""
  echo "━━━ Step 1/5: Archive ━━━"
  if ! archive_app; then
    echo "[appstore_submit] FAILED at archive step"
    return 1
  fi

  # Step 2: Export IPA
  echo ""
  echo "━━━ Step 2/5: Export IPA ━━━"
  if ! export_ipa; then
    echo "[appstore_submit] FAILED at export step"
    return 1
  fi

  # Step 3: Upload to App Store Connect
  echo ""
  echo "━━━ Step 3/5: Upload ━━━"
  if ! upload_to_appstore; then
    echo "[appstore_submit] FAILED at upload step"
    return 1
  fi

  # Step 4: Submit metadata
  echo ""
  echo "━━━ Step 4/5: Submit Metadata ━━━"
  submit_metadata || echo "[appstore_submit] Metadata submission had issues (non-fatal)"

  # Step 5: TestFlight distribution
  echo ""
  echo "━━━ Step 5/5: TestFlight ━━━"
  distribute_testflight || echo "[appstore_submit] TestFlight submission had issues (build may still be processing)"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "[appstore_submit] SUBMISSION COMPLETE FOR $APP_NAME"
  echo "[appstore_submit] Check status: bash orchestrator/appstore_submit.sh $PROJECT_DIR status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Notify Discord
  if [ -f "$ROOT_DIR/orchestrator/discord_notify.sh" ]; then
    source "$ROOT_DIR/orchestrator/discord_notify.sh"
    send_discord_notification "App Store Submission" \
      "$APP_NAME uploaded to App Store Connect and submitted to TestFlight!" \
      "5763719" 2>/dev/null || true
  fi
}

# ── Batch submit all ready apps ──────────────────────────────────
batch_submit() {
  echo "[appstore_submit] === BATCH SUBMISSION MODE ==="

  local submitted=0
  local failed=0
  local skipped=0

  for state_file in "$ROOT_DIR"/projects/*/state.json; do
    local proj_dir=$(dirname "$state_file")
    local proj_name=$(basename "$proj_dir")

    # Check if app is ready for submission (past phase 7)
    local phase=$(python3 -c "import json; print(json.load(open('$state_file')).get('phase', 0))" 2>/dev/null)
    local already_uploaded=$(python3 -c "import json; print(json.load(open('$state_file')).get('uploaded_to_appstore', False))" 2>/dev/null)

    if [ "$already_uploaded" = "True" ]; then
      echo "[batch] $proj_name — already uploaded, skipping"
      skipped=$((skipped + 1))
      continue
    fi

    if [ "$phase" -lt 7 ]; then
      echo "[batch] $proj_name — phase $phase (not ready), skipping"
      skipped=$((skipped + 1))
      continue
    fi

    echo ""
    echo "═══════════════════════════════════"
    echo "[batch] Submitting: $proj_name (phase $phase)"
    echo "═══════════════════════════════════"

    if bash "$0" "$proj_dir" full-submit; then
      submitted=$((submitted + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "═══ BATCH RESULTS ═══"
  echo "Submitted: $submitted"
  echo "Failed: $failed"
  echo "Skipped: $skipped"
}

# ── Main dispatch ────────────────────────────────────────────────
export PROJECT_DIR STATE_FILE APP_NAME BUNDLE_ID ASC_KEY_FILE

case "$ACTION" in
  archive)       validate_credentials && archive_app ;;
  export)        validate_credentials && export_ipa ;;
  upload)        validate_credentials && upload_to_appstore ;;
  metadata)      validate_credentials && submit_metadata ;;
  testflight)    validate_credentials && distribute_testflight ;;
  status)        validate_credentials && check_status ;;
  create-app)    validate_credentials && create_app_record ;;
  full-submit)   full_submit ;;
  batch)         validate_credentials && batch_submit ;;
  *)
    echo "Usage: appstore_submit.sh <project_dir> <action>"
    echo ""
    echo "Actions:"
    echo "  archive      - Build .xcarchive (signed for App Store)"
    echo "  export       - Export IPA from archive"
    echo "  upload       - Upload IPA to App Store Connect"
    echo "  metadata     - Submit app metadata (description, keywords, etc.)"
    echo "  testflight   - Distribute latest build to TestFlight"
    echo "  status       - Check App Store Connect processing status"
    echo "  create-app   - Create app record in App Store Connect"
    echo "  full-submit  - Run full pipeline: archive → export → upload → metadata → testflight"
    echo "  batch        - Submit ALL ready apps (phase >= 7)"
    exit 1
    ;;
esac
