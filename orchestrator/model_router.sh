#!/usr/bin/env bash
# OPENAGENT — Model Router
# Sources by each agent to get the optimal model for their phase.
# Supports tiered routing: haiku (cheap) → sonnet (balanced) → opus (premium)
#
# Usage in agent run.sh:
#   source "$ROOT_DIR/orchestrator/model_router.sh"
#   MODEL=$(get_model "research")         # Returns claude-haiku-4-5-20251001
#   MODEL=$(get_model "build")            # Returns claude-sonnet-4-20250514
#   MODEL=$(get_model "build" "complex")  # Returns claude-opus-4-20250514

# ── Model IDs ──────────────────────────────────────────────────────
# Claude (Anthropic) — used via `claude --print` CLI
MODEL_HAIKU="claude-haiku-4-5-20251001"
MODEL_SONNET="claude-sonnet-4-20250514"
MODEL_OPUS="claude-opus-4-6"

# Qwen (DashScope) — used via qwen_call.sh wrapper
MODEL_QWEN_PLUS="qwen-plus"
MODEL_QWEN_TURBO="qwen-turbo"

# ── Backend selection ─────────────────────────────────────────────
# "claude" = claude CLI, "qwen" = DashScope API
# Qwen handles all cheap/text phases (FREE). Claude handles code gen.
BACKEND_QWEN="qwen"
BACKEND_CLAUDE="claude"

# ── Premium Projects (get Opus for build/onboarding) ──────────────
PREMIUM_PROJECTS=("gem_os" "gem-os" "denta_vision" "denta-vision")

# ── Cost per 1M tokens (for estimation) ────────────────────────────
# Haiku:  $1.00 input / $5.00 output
# Sonnet: $3.00 input / $15.00 output
# Opus:   $15.00 input / $75.00 output
COST_HAIKU_IN=1.00
COST_HAIKU_OUT=5.00
COST_SONNET_IN=3.00
COST_SONNET_OUT=15.00
COST_OPUS_IN=15.00
COST_OPUS_OUT=75.00

# ── Phase → Model Mapping ──────────────────────────────────────────
# OPTIMIZED: Most phases downgraded from Sonnet/Opus to save ~80% costs
#
# Previous setup (all Anthropic, ~$15-25/app):
#   research=sonnet, validation=sonnet, build=opus, quality=sonnet,
#   monetization=sonnet, appstore_prep=sonnet, onboarding=opus,
#   screenshots=sonnet, promo=sonnet
#
# New setup (~$2-5/app):
#   research=haiku, validation=haiku, build=sonnet, quality=haiku,
#   monetization=sonnet, appstore_prep=haiku, onboarding=sonnet,
#   screenshots=haiku, promo=haiku
#   build_review=haiku

get_model() {
  local phase="${1:-}"
  local complexity="${2:-standard}"  # standard | complex
  local project="${3:-}"            # optional project name for premium override

  # Check if project is in the premium list
  local is_premium=false
  if [ -n "$project" ]; then
    for p in "${PREMIUM_PROJECTS[@]}"; do
      if [ "$p" = "$project" ]; then
        is_premium=true
        break
      fi
    done
  fi

  case "$phase" in
    # ── Free phases (Qwen) — research, validation, marketing ──
    research|validation|quality|appstore_prep|screenshots|promo)
      echo "$MODEL_QWEN_PLUS"
      ;;

    # ── Build phase — Opus for premium, Sonnet for standard ──
    build)
      if [ "$is_premium" = true ] || [ "$complexity" = "complex" ]; then
        echo "$MODEL_OPUS"
      else
        echo "$MODEL_SONNET"
      fi
      ;;
    build_review)
      echo "$MODEL_QWEN_PLUS"
      ;;
    monetization)
      if [ "$is_premium" = true ]; then
        echo "$MODEL_OPUS"
      else
        echo "$MODEL_SONNET"
      fi
      ;;
    onboarding)
      if [ "$is_premium" = true ]; then
        echo "$MODEL_OPUS"
      else
        echo "$MODEL_SONNET"
      fi
      ;;

    # ── Fallback ──
    *)
      echo "$MODEL_SONNET"
      ;;
  esac
}

# ── Backend Router ────────────────────────────────────────────────
# Returns "qwen" or "claude" based on the model ID.
# Agents use this to decide: qwen_call() vs claude --print
get_backend() {
  local model="${1:-}"
  case "$model" in
    qwen-*) echo "$BACKEND_QWEN" ;;
    claude-*) echo "$BACKEND_CLAUDE" ;;
    *) echo "$BACKEND_CLAUDE" ;;  # fallback to Claude
  esac
}

# ── Cost Estimator ──────────────────────────────────────────────────
estimate_cost() {
  local model="$1" input_tokens="$2" output_tokens="$3"

  case "$model" in
    *haiku*)
      python3 -c "print(f'{($input_tokens * $COST_HAIKU_IN + $output_tokens * $COST_HAIKU_OUT) / 1000000:.4f}')"
      ;;
    *sonnet*)
      python3 -c "print(f'{($input_tokens * $COST_SONNET_IN + $output_tokens * $COST_SONNET_OUT) / 1000000:.4f}')"
      ;;
    *opus*)
      python3 -c "print(f'{($input_tokens * $COST_OPUS_IN + $output_tokens * $COST_OPUS_OUT) / 1000000:.4f}')"
      ;;
  esac
}

# ── Model Display Name ──────────────────────────────────────────────
model_tier() {
  local model="$1"
  case "$model" in
    *haiku*) echo "haiku" ;;
    *sonnet*) echo "sonnet" ;;
    *opus*) echo "opus" ;;
    *) echo "unknown" ;;
  esac
}

# ── Savings Calculator ──────────────────────────────────────────────
# Call this to see estimated savings vs old config
print_savings_estimate() {
  cat <<'EOF'
┌─────────────────┬─────────────┬─────────────┬──────────────┐
│ Phase           │ Old Model   │ New Model   │ Est. Savings │
├─────────────────┼─────────────┼─────────────┼──────────────┤
│ Research        │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Validation      │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Build           │ Opus ($15)  │ Sonnet ($3) │ -80%         │
│ Build Review    │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Quality         │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Monetization    │ Sonnet ($3) │ Sonnet ($3) │  0%          │
│ App Store Prep  │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Onboarding      │ Opus ($15)  │ Sonnet ($3) │ -80%         │
│ Screenshots     │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
│ Promo           │ Sonnet ($3) │ Haiku ($1)  │ -67%         │
├─────────────────┼─────────────┼─────────────┼──────────────┤
│ TOTAL per app   │ ~$15-25     │ ~$2-5       │ -75 to -85%  │
└─────────────────┴─────────────┴─────────────┴──────────────┘
EOF
}
