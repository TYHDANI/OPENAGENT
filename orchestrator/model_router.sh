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

# Qwen (Ollama local) — used via qwen_call.sh wrapper
MODEL_QWEN="qwen3:4b"

# ── Backend selection ─────────────────────────────────────────────
# "claude" = claude CLI, "qwen" = Ollama local API (FREE)
# Qwen handles all cheap/text phases. Claude handles code gen.
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
# Max subscription — flat rate, no per-token cost.
# Strategy: Opus for code gen (builds), Qwen for text analysis (free).
#
#   research/validation/quality/marketing = Qwen 3 4B (Ollama, FREE)
#   build/monetization/onboarding         = Opus (best code gen)
#   build_review                          = Qwen (text analysis)

get_model() {
  local phase="${1:-}"
  local complexity="${2:-standard}"  # standard | complex
  local project="${3:-}"            # optional project name

  case "$phase" in
    # ── Free phases (Qwen Ollama) — text analysis, no code gen ──
    research|validation|quality|appstore_prep|screenshots|promo)
      echo "$MODEL_QWEN"
      ;;

    # ── Build phase — Opus for all builds (Max plan, flat rate) ──
    build)
      echo "$MODEL_OPUS"
      ;;
    build_review)
      echo "$MODEL_QWEN"
      ;;

    # ── Monetization — Opus (StoreKit code gen matters) ──
    monetization)
      echo "$MODEL_OPUS"
      ;;

    # ── Onboarding — Sonnet (good enough, saves rate limit for builds) ──
    onboarding)
      echo "$MODEL_SONNET"
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
    qwen*) echo "$BACKEND_QWEN" ;;
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

# ── Model Allocation (Max Plan) ──────────────────────────────────────
print_model_allocation() {
  cat <<'EOF'
┌─────────────────┬─────────────┬──────────────┐
│ Phase           │ Model       │ Backend      │
├─────────────────┼─────────────┼──────────────┤
│ Research        │ Qwen 3 4B   │ Ollama (FREE)│
│ Validation      │ Qwen 3 4B   │ Ollama (FREE)│
│ Build           │ Opus 4.6    │ Claude Max   │
│ Build Review    │ Qwen 3 4B   │ Ollama (FREE)│
│ Quality         │ Qwen 3 4B   │ Ollama (FREE)│
│ Monetization    │ Opus 4.6    │ Claude Max   │
│ App Store Prep  │ Qwen 3 4B   │ Ollama (FREE)│
│ Onboarding      │ Sonnet 4    │ Claude Max   │
│ Screenshots     │ Qwen 3 4B   │ Ollama (FREE)│
│ Promo           │ Qwen 3 4B   │ Ollama (FREE)│
├─────────────────┼─────────────┼──────────────┤
│ Cost per app    │ $0 (flat)   │ Max plan     │
└─────────────────┴─────────────┴──────────────┘
EOF
}
