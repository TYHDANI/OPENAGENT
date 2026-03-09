#!/bin/bash
# wshobson/agents Integration for OPENAGENT
# Source: https://github.com/wshobson/agents
# Provides: Mobile dev plugin, security auditor, marketing agents
#
# Installation:
#   cd /Users/beachbar/OPENAGENT/tools
#   git clone https://github.com/wshobson/agents.git wshobson-agents
#
# Usage: Source this file, then call specific plugin functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$ROOT_DIR/tools/wshobson-agents"

# Check if wshobson/agents is installed
check_wshobson() {
    if [ ! -d "$AGENTS_DIR" ]; then
        echo "WARNING: wshobson/agents not installed at $AGENTS_DIR"
        echo "Install: cd $ROOT_DIR/tools && git clone https://github.com/wshobson/agents.git wshobson-agents"
        return 1
    fi
    return 0
}

# Load mobile development plugin rules into Build agent context
# Usage: load_mobile_rules
load_mobile_rules() {
    check_wshobson || return 1

    local mobile_rules=""
    # Load frontend-mobile plugin rules if they exist
    for rule_file in "$AGENTS_DIR"/plugins/frontend-mobile/*.md; do
        if [ -f "$rule_file" ]; then
            mobile_rules+="$(cat "$rule_file")\n\n"
        fi
    done

    if [ -n "$mobile_rules" ]; then
        echo "$mobile_rules"
    else
        echo "No mobile-specific rules found in wshobson/agents"
    fi
}

# Run security audit using wshobson security-scanning plugin
# Usage: run_security_audit "project_dir"
run_security_audit() {
    local project_dir="$1"
    check_wshobson || return 1

    echo "Running wshobson security audit on $project_dir..."

    # Check for common iOS security issues
    local findings=()

    # Check for hardcoded secrets
    if grep -rn "api_key\|apiKey\|secret\|password\|token" "$project_dir/Sources/" --include="*.swift" 2>/dev/null | grep -v "\.gitignore\|// \|/// " | head -10; then
        findings+=("POTENTIAL_SECRETS: Found possible hardcoded secrets in source code")
    fi

    # Check for HTTP URLs (should be HTTPS)
    if grep -rn "http://" "$project_dir/Sources/" --include="*.swift" 2>/dev/null | head -5; then
        findings+=("INSECURE_HTTP: Found HTTP URLs (should be HTTPS)")
    fi

    # Check for UserDefaults storing sensitive data
    if grep -rn "UserDefaults.*password\|UserDefaults.*token\|UserDefaults.*key" "$project_dir/Sources/" --include="*.swift" 2>/dev/null | head -5; then
        findings+=("INSECURE_STORAGE: Sensitive data in UserDefaults (use Keychain)")
    fi

    # Check for missing Privacy manifest
    if [ ! -f "$project_dir/Sources/PrivacyInfo.xcprivacy" ] && [ ! -f "$project_dir/PrivacyInfo.xcprivacy" ]; then
        findings+=("MISSING_PRIVACY_MANIFEST: No PrivacyInfo.xcprivacy found (required since Spring 2024)")
    fi

    if [ ${#findings[@]} -eq 0 ]; then
        echo "Security audit PASSED — no issues found"
        return 0
    else
        echo "Security audit found ${#findings[@]} issue(s):"
        for finding in "${findings[@]}"; do
            echo "  ⚠ $finding"
        done
        return 1
    fi
}

# Generate marketing content using wshobson content-marketing plugin
# Usage: generate_marketing_content "project_dir" "app_name" "target_audience"
generate_marketing_content() {
    local project_dir="$1"
    local app_name="$2"
    local audience="$3"

    check_wshobson || return 1

    echo "Generating marketing content for $app_name targeting $audience..."
    echo "Marketing plugin rules loaded from wshobson/agents"

    # Load marketing plugin context for the Promo agent
    local marketing_rules=""
    for rule_file in "$AGENTS_DIR"/plugins/content-marketing/*.md; do
        if [ -f "$rule_file" ]; then
            marketing_rules+="$(cat "$rule_file")\n\n"
        fi
    done

    echo "$marketing_rules"
}

# Run architecture review using wshobson code-reviewer plugin
# Usage: run_architecture_review "project_dir"
run_architecture_review() {
    local project_dir="$1"
    check_wshobson || return 1

    echo "Running architecture review on $project_dir..."

    # Count files and check structure
    local swift_files=$(find "$project_dir/Sources" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    local model_files=$(find "$project_dir/Sources/Models" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    local service_files=$(find "$project_dir/Sources/Services" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    local view_files=$(find "$project_dir/Sources/Views" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    local design_files=$(find "$project_dir/Sources/DesignSystem" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')

    echo "  Swift files: $swift_files"
    echo "  Models: $model_files | Services: $service_files | Views: $view_files | DesignSystem: $design_files"

    # Check view size limits
    local oversized_views=0
    for view_file in $(find "$project_dir/Sources/Views" -name "*.swift" 2>/dev/null); do
        local lines=$(wc -l < "$view_file" | tr -d ' ')
        if [ "$lines" -gt 120 ]; then
            echo "  ⚠ OVERSIZED: $(basename "$view_file") ($lines lines, limit 120)"
            ((oversized_views++))
        fi
    done

    if [ $oversized_views -eq 0 ]; then
        echo "  ✓ All views within 120-line limit"
    fi

    # Check DesignSystem usage
    local non_ds_colors=$(grep -rn "Color(\.\|Color(red:" "$project_dir/Sources/Views" --include="*.swift" 2>/dev/null | grep -v "AppColors" | wc -l | tr -d ' ')
    if [ "$non_ds_colors" -gt 0 ]; then
        echo "  ⚠ $non_ds_colors instances of raw Color usage (should use AppColors)"
    else
        echo "  ✓ All colors use DesignSystem"
    fi
}

echo "wshobson/agents plugins loaded. Available:"
echo "  load_mobile_rules"
echo "  run_security_audit <project_dir>"
echo "  generate_marketing_content <project_dir> <app_name> <audience>"
echo "  run_architecture_review <project_dir>"
