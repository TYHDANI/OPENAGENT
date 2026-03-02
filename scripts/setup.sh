#!/usr/bin/env bash
# OPENAGENT — One-time setup script
# Installs dependencies and validates the environment.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "╔══════════════════════════════════════════╗"
echo "║        OPENAGENT Setup                   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

ERRORS=0

# ── Check Xcode CLI Tools ────────────────────────────────────────
echo "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  echo "  [OK] Xcode CLI tools installed at $(xcode-select -p)"
else
  echo "  [!!] Xcode CLI tools not found. Installing..."
  xcode-select --install
  ERRORS=$((ERRORS + 1))
fi

# ── Check Xcode ──────────────────────────────────────────────────
echo "Checking Xcode..."
XCODE_INSTALLED=false
if [ -d "/Applications/Xcode.app" ]; then
  XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1 || echo "unknown")
  echo "  [OK] $XCODE_VER"
  XCODE_INSTALLED=true
else
  echo "  [!!] Xcode.app not found. Install from the App Store (required for iOS builds)."
  echo "       After installing, run:"
  echo "         sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "         sudo xcodebuild -license accept"
  ERRORS=$((ERRORS + 1))
fi

# ── Check Claude CLI ────────────────────────────────────────────
echo "Checking Claude Code CLI..."
if command -v claude &>/dev/null; then
  CLAUDE_VER=$(claude --version 2>/dev/null || echo "installed")
  echo "  [OK] Claude CLI: $CLAUDE_VER"
else
  echo "  [!!] Claude CLI not found. Install from https://claude.ai/code"
  ERRORS=$((ERRORS + 1))
fi

# ── Check Python 3 ──────────────────────────────────────────────
echo "Checking Python 3..."
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version)
  echo "  [OK] $PY_VER"
else
  echo "  [!!] Python 3 not found. Install via: brew install python3"
  ERRORS=$((ERRORS + 1))
fi

# ── Check SwiftLint ─────────────────────────────────────────────
echo "Checking SwiftLint..."
if command -v swiftlint &>/dev/null; then
  LINT_VER=$(swiftlint version 2>/dev/null || echo "installed")
  echo "  [OK] SwiftLint $LINT_VER"
elif [ "$XCODE_INSTALLED" = false ]; then
  echo "  [..] SwiftLint skipped — install Xcode.app first, then re-run setup"
else
  echo "  [..] SwiftLint not found. Installing via Homebrew..."
  if command -v brew &>/dev/null; then
    if brew install swiftlint; then
      echo "  [OK] SwiftLint installed"
    else
      echo "  [!!] SwiftLint install failed. Install manually: brew install swiftlint"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "  [!!] Homebrew not found. Install SwiftLint manually."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ── Check iOS Simulators ────────────────────────────────────────
echo "Checking iOS Simulators..."
SIM_COUNT=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone" || echo "0")
echo "  [OK] $SIM_COUNT iPhone simulators available"

# ── Check environment variables ─────────────────────────────────
echo ""
echo "Checking environment variables..."

check_env() {
  local var_name="$1"
  local description="$2"
  if [ -n "${!var_name:-}" ]; then
    echo "  [OK] $var_name is set"
  else
    echo "  [..] $var_name not set — $description"
  fi
}

check_env "ANTHROPIC_API_KEY" "Required for Claude API access"
check_env "APPLE_DEVELOPER_TEAM_ID" "Your Apple Developer Team ID"

# ── Make scripts executable ─────────────────────────────────────
echo ""
echo "Making scripts executable..."
find "$ROOT_DIR" -name "*.sh" -exec chmod +x {} \;
echo "  [OK] All .sh files are now executable"

# ── Install Python dependencies (for dashboard) ─────────────────
echo ""
echo "Installing Python dependencies..."
if pip3 install fastapi uvicorn 2>/dev/null; then
  echo "  [OK] FastAPI + Uvicorn installed"
else
  echo "  [..] Could not install FastAPI. Dashboard will not work."
fi

# ── Validate directory structure ─────────────────────────────────
echo ""
echo "Validating directory structure..."
REQUIRED_DIRS=(
  "orchestrator"
  "agents/01_research"
  "agents/02_validation"
  "agents/03_build"
  "agents/04_quality"
  "agents/05_monetization"
  "agents/06_appstore_prep"
  "agents/07_onboarding"
  "agents/08_screenshots"
  "agents/09_promo"
  "projects/_template"
  "ideas"
  "logs"
  "dashboard"
  "scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$ROOT_DIR/$dir" ]; then
    echo "  [OK] $dir/"
  else
    echo "  [!!] Missing: $dir/"
    ERRORS=$((ERRORS + 1))
  fi
done

# ── Summary ─────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
if [ "$ERRORS" -eq 0 ]; then
  echo "Setup complete. No errors found."
  echo ""
  echo "Next steps:"
  echo "  1. Set your ANTHROPIC_API_KEY in your shell profile"
  echo "  2. Drop an app idea into ideas/  (or run: ./scripts/add_idea.sh \"My App\")"
  echo "  3. Start the orchestrator: ./orchestrator/littlegreenman.sh"
  echo "  4. Or set up cron: */5 * * * * cd $ROOT_DIR && ./orchestrator/littlegreenman.sh"
  echo "  5. Monitor at: python3 dashboard/server.py  (http://localhost:8420)"
else
  echo "Setup complete with $ERRORS issue(s). Fix them before running."
fi
echo "════════════════════════════════════════════"
