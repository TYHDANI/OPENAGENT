#!/usr/bin/env bash
# OPENAGENT — Qwen 3 API Wrapper (Ollama)
# Local Ollama endpoint for Qwen models — FREE, runs on VPS.
# Used for cheap phases: research, validation, quality, marketing.
#
# Usage:
#   source "$ROOT_DIR/orchestrator/qwen_call.sh"
#   response=$(qwen_call "Analyze this market data..." "qwen3:4b")
#   qwen_call_to_file "Write a report..." "$PROJECT_DIR/report.md" "qwen3:4b"

OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3:4b}"

# ── Core API Call ─────────────────────────────────────────────────
# Returns the model's text response to stdout.
# Args: $1=prompt, $2=model (default: qwen3:4b), $3=max_tokens (default: 8192)
qwen_call() {
  local prompt="$1"
  local model="${2:-$OLLAMA_MODEL}"
  local max_tokens="${3:-8192}"

  # Escape the prompt for JSON
  local json_prompt
  json_prompt=$(python3 -c "
import json, sys
prompt = sys.stdin.read()
print(json.dumps(prompt))
" <<< "$prompt")

  local response
  response=$(curl -s --max-time 600 "$OLLAMA_ENDPOINT/api/chat" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": $json_prompt}],
      \"stream\": false,
      \"options\": {
        \"num_predict\": $max_tokens,
        \"temperature\": 0.7
      }
    }" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo "[qwen_call] ERROR: Ollama request failed" >&2
    return 1
  fi

  # Check for errors and extract content
  local content
  content=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print(f'ERROR: {data[\"error\"]}', file=sys.stderr)
        sys.exit(1)
    msg = data.get('message', {})
    content = msg.get('content', '')
    if not content:
        print('ERROR: No content in response', file=sys.stderr)
        sys.exit(1)
    # Strip thinking tags if present (Qwen3 uses /think)
    import re
    content = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL).strip()
    print(content)
except Exception as e:
    print(f'Parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$content" ]; then
    echo "[qwen_call] ERROR: Failed to parse Ollama response" >&2
    return 1
  fi

  echo "$content"
}

# ── Call and write to file ────────────────────────────────────────
# Args: $1=prompt, $2=output_file, $3=model (default: qwen3:4b)
qwen_call_to_file() {
  local prompt="$1"
  local output_file="$2"
  local model="${3:-$OLLAMA_MODEL}"

  local result
  result=$(qwen_call "$prompt" "$model")
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "[qwen_call] Failed to get response for: $output_file" >&2
    return 1
  fi

  echo "$result" > "$output_file"
  echo "[qwen_call] Written $(wc -l < "$output_file" | tr -d ' ') lines to $output_file"
  return 0
}

# ── Multi-file response writer ───────────────────────────────────
# Parses ===FILE: path=== ... ===ENDFILE=== blocks from response
qwen_write_files() {
  local response_file="$1"
  local base_dir="$2"

  python3 << 'PYEOF' "$response_file" "$base_dir"
import re, sys, os

response_file = sys.argv[1]
base_dir = sys.argv[2]

with open(response_file, 'r') as f:
    response = f.read()

pattern = r'===FILE:\s*(.+?)\s*===(.*?)===ENDFILE==='
matches = re.findall(pattern, response, re.DOTALL)

files_written = 0
for filepath, content in matches:
    filepath = filepath.strip()
    if not os.path.isabs(filepath):
        full_path = os.path.join(base_dir, filepath)
    else:
        full_path = filepath
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content.strip() + '\n')
    print(f'[qwen_write] Wrote: {full_path}')
    files_written += 1

if files_written == 0:
    fallback = os.path.join(base_dir, 'agent_output.md')
    with open(fallback, 'w') as f:
        f.write(response.strip() + '\n')
    print(f'[qwen_write] No markers found, wrote to: {fallback}')

print(f'[qwen_write] Total files written: {files_written}')
PYEOF
}

# ── Run agent with Qwen or Claude ────────────────────────────────
# Usage: run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "phase_key" "value"
run_with_model() {
  local prompt="$1"
  local model="$2"
  local project_dir="$3"
  local state_file="$4"
  local state_key="${5:-}"
  local state_val="${6:-true}"

  local backend
  backend=$(get_backend "$model")

  if [ "$backend" = "qwen" ]; then
    echo "[agent] Using Ollama Qwen: $model"
    local tmp_response
    tmp_response=$(mktemp /tmp/qwen_response.XXXXXX)

    if qwen_call "$prompt" "$model" > "$tmp_response" 2>/dev/null; then
      qwen_write_files "$tmp_response" "$project_dir"

      if [ -n "$state_key" ] && [ -f "$state_file" ]; then
        python3 -c "
import json
from datetime import datetime, timezone
with open('$state_file', 'r') as f:
    state = json.load(f)
state['$state_key'] = $state_val if '$state_val' in ('true','false') else '$state_val'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
with open('$state_file', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
      fi

      rm -f "$tmp_response"
      return 0
    else
      echo "[agent] Ollama Qwen failed. Falling back to Claude Haiku."
      rm -f "$tmp_response"
      model="$MODEL_HAIKU"
      backend="claude"
    fi
  fi

  # Claude path (original or fallback)
  if [ "$backend" = "claude" ]; then
    echo "[agent] Using Claude: $model"
    if claude --print --dangerously-skip-permissions --model "$model" "$prompt" < /dev/null; then
      return 0
    else
      return 1
    fi
  fi
}
