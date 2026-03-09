#!/usr/bin/env bash
# ane_train.sh — ANE (Apple Neural Engine) Training Pipeline Phase
# Integrates on-device model fine-tuning into OPENAGENT app factory
#
# REQUIREMENTS:
#   - Apple Silicon Mac (M1/M2/M3/M4/M5) — Intel Macs have no ANE
#   - ANE repo built at /Volumes/T7/ANE/training/
#   - Model weights at /Volumes/T7/ANE/assets/models/
#
# USAGE:
#   source orchestrator/ane_train.sh
#   ane_check_hardware        # verify M-series silicon + ANE available
#   ane_train_model "project" # fine-tune model for a specific app
#   ane_export_coreml "project" # export to CoreML .mlmodel for app embedding

set -euo pipefail

ANE_REPO="/Volumes/T7/ANE"
ANE_TRAINING="${ANE_REPO}/training"
ANE_MODELS="${ANE_REPO}/assets/models"
OPENAGENT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDS_DIR="/Volumes/T7/OPENAGENT_builds"
LOG_FILE="${OPENAGENT_ROOT}/logs/ane_training.jsonl"

# ============================================================
# Hardware Detection
# ============================================================

ane_check_hardware() {
    local arch
    arch=$(uname -m)

    if [[ "$arch" != "arm64" ]]; then
        echo "ERROR: ANE requires Apple Silicon (arm64). Detected: $arch"
        echo "ANE training is unavailable on Intel Macs."
        echo "Options:"
        echo "  1. Use an Apple Silicon Mac (M1/M2/M3/M4)"
        echo "  2. Skip ANE phase — apps work fine without on-device training"
        return 1
    fi

    # Check if ANE binaries exist
    if [[ ! -x "${ANE_TRAINING}/train_large" ]]; then
        echo "ANE binaries not found. Building..."
        cd "${ANE_TRAINING}" && make train_large 2>&1
    fi

    echo "ANE hardware: OK ($(sysctl -n machdep.cpu.brand_string))"
    echo "ANE binary: ${ANE_TRAINING}/train_large"
    return 0
}

# ============================================================
# Model Training Configuration Per App
# ============================================================

ane_get_config() {
    local project="$1"

    case "$project" in
        yieldsentinel)
            echo "task=risk_scoring"
            echo "description=DeFi yield product risk classification"
            echo "labels=safe,caution,warning,danger"
            echo "input=protocol_metrics"
            ;;
        denta-vision)
            echo "task=image_classification"
            echo "description=Dental condition detection from X-ray images"
            echo "labels=healthy,cavity,filling,crown,missing,other"
            echo "input=dental_xray"
            ;;
        gem-os)
            echo "task=regression"
            echo "description=Gemstone quality prediction from synthesis parameters"
            echo "labels=quality_score"
            echo "input=reactor_params"
            ;;
        legacyvault)
            echo "task=anomaly_detection"
            echo "description=Wallet activity anomaly detection for dormancy triggers"
            echo "labels=normal,dormant,suspicious,compromised"
            echo "input=transaction_history"
            ;;
        habit-streak)
            echo "task=time_series"
            echo "description=Habit completion prediction for smart reminders"
            echo "labels=will_complete,at_risk,will_skip"
            echo "input=habit_history"
            ;;
        treasurypilot)
            echo "task=classification"
            echo "description=Transaction categorization for multi-entity tax tracking"
            echo "labels=buy,sell,transfer,income,fee,airdrop,staking_reward"
            echo "input=transaction_data"
            ;;
        materialsource)
            echo "task=matching"
            echo "description=Material-supplier matching and RFQ routing"
            echo "labels=match_score"
            echo "input=material_specs"
            ;;
        *)
            echo "task=generic"
            echo "description=Generic fine-tuning for $project"
            echo "labels=positive,negative"
            echo "input=text"
            ;;
    esac
}

# ============================================================
# Training Workflow
# ============================================================

ane_train_model() {
    local project="$1"
    local steps="${2:-1000}"
    local lr="${3:-1e-4}"

    echo "=== ANE Training: $project ==="

    # Check hardware
    if ! ane_check_hardware; then
        echo "Skipping ANE training — no Apple Silicon"
        _ane_log "$project" "skipped" "no_apple_silicon"
        return 0
    fi

    # Get project config
    local config
    config=$(ane_get_config "$project")
    echo "$config"

    # Check for project-specific training data
    local data_dir="${BUILDS_DIR}/${project}/training_data"
    if [[ ! -d "$data_dir" ]]; then
        echo "No training data at $data_dir"
        echo "To prepare training data, create:"
        echo "  ${data_dir}/train.bin  — pretokenized uint16 training data"
        echo "  ${data_dir}/val.bin    — pretokenized uint16 validation data"
        echo "Skipping ANE training."
        _ane_log "$project" "skipped" "no_training_data"
        return 0
    fi

    # Run training
    local ckpt="${BUILDS_DIR}/${project}/ane_checkpoint.bin"
    local model="${ANE_MODELS}/stories110M.bin"

    echo "Training: steps=$steps, lr=$lr"
    echo "Model: $model"
    echo "Data: $data_dir/train.bin"
    echo "Checkpoint: $ckpt"

    cd "${ANE_TRAINING}"

    local start_time
    start_time=$(date +%s)

    if [[ -f "$ckpt" ]]; then
        echo "Resuming from checkpoint..."
        ./train_large --resume --ckpt "$ckpt" --data "$data_dir/train.bin" --steps "$steps" --lr "$lr" 2>&1 | tee "${BUILDS_DIR}/${project}/ane_train.log"
    else
        ./train_large "$model" --data "$data_dir/train.bin" --steps "$steps" --lr "$lr" --ckpt "$ckpt" 2>&1 | tee "${BUILDS_DIR}/${project}/ane_train.log"
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "Training complete in ${duration}s"
    _ane_log "$project" "completed" "steps=${steps},lr=${lr},duration=${duration}s"

    return 0
}

# ============================================================
# CoreML Export
# ============================================================

ane_export_coreml() {
    local project="$1"
    local ckpt="${BUILDS_DIR}/${project}/ane_checkpoint.bin"
    local output="${BUILDS_DIR}/${project}/Sources/Resources/${project}_model.mlmodel"

    if [[ ! -f "$ckpt" ]]; then
        echo "No checkpoint found at $ckpt — run ane_train_model first"
        return 1
    fi

    echo "Exporting CoreML model..."
    echo "Checkpoint: $ckpt"
    echo "Output: $output"

    # CoreML export requires converting ANE checkpoint weights to CoreML format
    # This is a bridge script that:
    # 1. Reads the ANE checkpoint (custom binary format)
    # 2. Creates equivalent PyTorch/MLX model
    # 3. Exports to CoreML via coremltools
    python3 "${OPENAGENT_ROOT}/scripts/ane_to_coreml.py" \
        --checkpoint "$ckpt" \
        --output "$output" \
        --project "$project" 2>&1

    if [[ -f "$output" ]]; then
        local size
        size=$(du -h "$output" | cut -f1)
        echo "CoreML model exported: $output ($size)"
        _ane_log "$project" "exported" "path=$output,size=$size"
    else
        echo "Export failed — see logs"
        _ane_log "$project" "export_failed" "no_output"
        return 1
    fi
}

# ============================================================
# Pipeline Integration
# ============================================================

ane_pipeline_phase() {
    # Called by the main OPENAGENT pipeline after build phase
    local project="$1"
    local state_file="${OPENAGENT_ROOT}/projects/${project}/state.json"

    echo "=== ANE Pipeline Phase: $project ==="

    # Check if project has ANE training enabled
    local ane_enabled
    ane_enabled=$(python3 -c "
import json
with open('$state_file') as f:
    d = json.load(f)
print(d.get('ane_training', False))
" 2>/dev/null || echo "False")

    if [[ "$ane_enabled" != "True" ]]; then
        echo "ANE training not enabled for $project (set ane_training: true in state.json)"
        return 0
    fi

    # Train
    ane_train_model "$project"

    # Export
    ane_export_coreml "$project"

    # Update state
    python3 -c "
import json
with open('$state_file') as f:
    d = json.load(f)
d['ane_model_trained'] = True
with open('$state_file', 'w') as f:
    json.dump(d, f, indent=2)
print('State updated: ane_model_trained=True')
"
}

# ============================================================
# Logging
# ============================================================

_ane_log() {
    local project="$1"
    local status="$2"
    local details="$3"

    mkdir -p "$(dirname "$LOG_FILE")"

    printf '{"timestamp":"%s","project":"%s","phase":"ane_training","status":"%s","details":"%s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "$project" \
        "$status" \
        "$details" \
        >> "$LOG_FILE"
}

# ============================================================
# Status Report
# ============================================================

ane_status() {
    echo "=== ANE Training Status ==="
    echo ""

    # Hardware
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "Hardware: Apple Silicon ($(sysctl -n machdep.cpu.brand_string))"
        echo "ANE: AVAILABLE"
    else
        echo "Hardware: Intel ($arch)"
        echo "ANE: NOT AVAILABLE — requires Apple Silicon"
    fi
    echo ""

    # Binary
    if [[ -x "${ANE_TRAINING}/train_large" ]]; then
        echo "Training binary: BUILT"
    else
        echo "Training binary: NOT BUILT (run: cd ${ANE_TRAINING} && make train_large)"
    fi
    echo ""

    # Per-project status
    echo "Project Training Status:"
    for proj_dir in "${OPENAGENT_ROOT}/projects"/*/; do
        local proj
        proj=$(basename "$proj_dir")
        [[ "$proj" == "_template" ]] && continue

        local ckpt="${BUILDS_DIR}/${proj}/ane_checkpoint.bin"
        local model="${BUILDS_DIR}/${proj}/Sources/Resources/${proj}_model.mlmodel"

        local train_status="not_started"
        [[ -f "$ckpt" ]] && train_status="checkpoint_exists"
        [[ -f "$model" ]] && train_status="coreml_exported"

        printf "  %-20s %s\n" "$proj" "$train_status"
    done
    echo ""

    # Recent logs
    if [[ -f "$LOG_FILE" ]]; then
        echo "Recent training activity:"
        tail -5 "$LOG_FILE" | while IFS= read -r line; do
            echo "  $line"
        done
    fi
}

echo "ANE training functions loaded. Commands:"
echo "  ane_check_hardware     — verify Apple Silicon + ANE"
echo "  ane_train_model <proj> — fine-tune model for app"
echo "  ane_export_coreml <proj> — export to CoreML"
echo "  ane_pipeline_phase <proj> — full pipeline phase"
echo "  ane_status             — show training status"
