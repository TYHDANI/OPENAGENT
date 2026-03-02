#!/usr/bin/env bash
set -euo pipefail

# security_check.sh — Security scanner for iOS/Swift projects
# Usage: security_check.sh <project_dir>
# Outputs: score 0-10 on stdout (10 if clean, 0 if any secrets found)
# Exit 0 on success (score computed), 1 on error

PROJECT_DIR="${1:?Usage: security_check.sh <project_dir>}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory does not exist: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

ISSUES=0
DETAILS=""

# ---------------------------------------------------------------------------
# Helper: scan files with a pattern and report matches
# ---------------------------------------------------------------------------
scan_pattern() {
    local label="$1"
    local pattern="$2"
    local matches

    matches=$(grep -rn --include="*.swift" --include="*.plist" --include="*.json" \
        --include="*.yaml" --include="*.yml" --include="*.xml" --include="*.m" \
        --include="*.h" --include="*.strings" \
        -E "$pattern" "$PROJECT_DIR" \
        --exclude-dir=Pods \
        --exclude-dir=.build \
        --exclude-dir=DerivedData \
        --exclude-dir=Carthage \
        --exclude-dir=.git \
        2>/dev/null || true)

    if [[ -n "$matches" ]]; then
        local count
        count=$(echo "$matches" | wc -l | xargs)
        ISSUES=$((ISSUES + count))
        DETAILS="${DETAILS}\n[$label] $count occurrence(s) found:"
        DETAILS="${DETAILS}\n$(echo "$matches" | head -5)"
        if [[ "$count" -gt 5 ]]; then
            DETAILS="${DETAILS}\n  ... and $((count - 5)) more"
        fi
    fi
}

echo "Scanning for security issues in: $PROJECT_DIR" >&2

# ---------------------------------------------------------------------------
# 1. Hardcoded API keys (common patterns)
# ---------------------------------------------------------------------------
scan_pattern "HARDCODED_API_KEY" \
    '(api[_-]?key|apikey)\s*[:=]\s*"[A-Za-z0-9_\-]{16,}"'

# ---------------------------------------------------------------------------
# 2. Hardcoded passwords
# ---------------------------------------------------------------------------
scan_pattern "HARDCODED_PASSWORD" \
    '(password|passwd|secret)\s*[:=]\s*"[^"]{4,}"'

# ---------------------------------------------------------------------------
# 3. AWS keys
# ---------------------------------------------------------------------------
scan_pattern "AWS_ACCESS_KEY" \
    'AKIA[0-9A-Z]{16}'

# ---------------------------------------------------------------------------
# 4. Generic secret tokens (Bearer tokens, authorization headers with values)
# ---------------------------------------------------------------------------
scan_pattern "BEARER_TOKEN" \
    'Bearer\s+[A-Za-z0-9_\-\.]{20,}'

# ---------------------------------------------------------------------------
# 5. Private keys embedded in source
# ---------------------------------------------------------------------------
scan_pattern "PRIVATE_KEY" \
    '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'

# ---------------------------------------------------------------------------
# 6. Firebase / Google service keys
# ---------------------------------------------------------------------------
scan_pattern "FIREBASE_KEY" \
    'AIza[0-9A-Za-z_\-]{35}'

# ---------------------------------------------------------------------------
# 7. Hardcoded URLs with credentials (user:pass@host)
# ---------------------------------------------------------------------------
scan_pattern "URL_WITH_CREDENTIALS" \
    'https?://[^:]+:[^@]+@[a-zA-Z0-9]'

# ---------------------------------------------------------------------------
# 8. .env files committed or referenced
# ---------------------------------------------------------------------------
if find "$PROJECT_DIR" -name ".env" -not -path "*/.git/*" 2>/dev/null | grep -q .; then
    ENV_FILES=$(find "$PROJECT_DIR" -name ".env" -not -path "*/.git/*" 2>/dev/null)
    ENV_COUNT=$(echo "$ENV_FILES" | wc -l | xargs)
    ISSUES=$((ISSUES + ENV_COUNT))
    DETAILS="${DETAILS}\n[ENV_FILE] $ENV_COUNT .env file(s) found in project tree"
fi

# ---------------------------------------------------------------------------
# 9. Check for proper Keychain usage (positive signal)
# ---------------------------------------------------------------------------
KEYCHAIN_USAGE=$(grep -rn --include="*.swift" \
    -E "(SecItemAdd|SecItemCopyMatching|SecItemUpdate|SecItemDelete|KeychainWrapper|KeychainAccess|kSecClass)" \
    "$PROJECT_DIR" \
    --exclude-dir=Pods --exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=Carthage \
    2>/dev/null | wc -l | xargs)

if [[ "$KEYCHAIN_USAGE" -gt 0 ]]; then
    echo "Keychain API usage detected: $KEYCHAIN_USAGE reference(s) (good practice)" >&2
else
    echo "WARNING: No Keychain API usage detected — secrets may not be stored securely" >&2
fi

# ---------------------------------------------------------------------------
# 10. Check for NSAppTransportSecurity AllowsArbitraryLoads
# ---------------------------------------------------------------------------
ATS_BYPASS=$(grep -rn --include="*.plist" \
    "NSAllowsArbitraryLoads" "$PROJECT_DIR" \
    --exclude-dir=Pods --exclude-dir=.build --exclude-dir=DerivedData \
    2>/dev/null || true)

if [[ -n "$ATS_BYPASS" ]]; then
    ATS_COUNT=$(echo "$ATS_BYPASS" | wc -l | xargs)
    ISSUES=$((ISSUES + ATS_COUNT))
    DETAILS="${DETAILS}\n[ATS_BYPASS] App Transport Security exceptions found ($ATS_COUNT)"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [[ -n "$DETAILS" ]]; then
    echo -e "\nSecurity issues found:" >&2
    echo -e "$DETAILS" >&2
fi

echo "" >&2
echo "Total security issues: $ISSUES" >&2
echo "Keychain references: $KEYCHAIN_USAGE" >&2

# Score: 10 if clean, 0 if any secrets found (binary for security)
if [[ "$ISSUES" -gt 0 ]]; then
    echo "SECURITY CHECK FAILED — secrets or vulnerabilities detected" >&2
    echo 0
else
    echo "Security check passed — no secrets or vulnerabilities detected" >&2
    echo 10
fi

exit 0
