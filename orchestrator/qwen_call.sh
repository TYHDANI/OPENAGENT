#!/usr/bin/env bash
# OPENAGENT — Qwen 3.5 API Wrapper (DashScope)
# OpenAI-compatible endpoint for Alibaba Cloud Qwen models.
# Used for cheap/free phases: research, validation, quality, marketing.
#
# Usage:
#   source "$ROOT_DIR/orchestrator/qwen_call.sh"
#   response=$(qwen_call "Analyze this market data and write a report..." "qwen-plus")
#   qwen_call_to_file "Write a one-pager..." "$PROJECT_DIR/one_pager.md" "qwen-plus"

DASHSCOPE_ENDPOINT="https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-}"

# ── Core API Call ─────────────────────────────────────────────────
# Returns the model's text response to stdout.
# Args: $1=prompt, $2=model (default: qwen-plus), $3=max_tokens (default: 8192)
qwen_call() {
  local prompt="$1"
  local model="${2:-qwen-plus}"
  local max_tokens="${3:-8192}"

  if [ -z "$DASHSCOPE_API_KEY" ]; then
    echo "[qwen_call] ERROR: DASHSCOPE_API_KEY not set" >&2
    return 1
  fi

  # Escape the prompt for JSON (handle newlines, quotes, backslashes)
  local json_prompt
  json_prompt=$(python3 -c "
import json, sys
prompt = sys.stdin.read()
print(json.dumps(prompt))
" <<< "$prompt")

  local response
  response=$(curl -s --max-time 120 "$DASHSCOPE_ENDPOINT" \
    -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": $json_prompt}],
      \"max_tokens\": $max_tokens,
      \"temperature\": 0.7
    }" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo "[qwen_call] ERROR: API request failed" >&2
    return 1
  fi

  # Check for API errors
  local error
  error=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print(data['error'].get('message', 'Unknown error'))
    elif 'choices' not in data:
        print('No choices in response')
    else:
        print('')
except Exception as e:
    print(f'Parse error: {e}')
" 2>/dev/null)

  if [ -n "$error" ]; then
    echo "[qwen_call] ERROR: $error" >&2
    echo "[qwen_call] Raw response: $response" >&2
    return 1
  fi

  # Extract text content
  echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    content = data['choices'][0]['message']['content']
    print(content)
except Exception as e:
    print(f'[qwen_call] Parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

# ── Call and write to file ────────────────────────────────────────
# Args: $1=prompt, $2=output_file, $3=model (default: qwen-plus)
qwen_call_to_file() {
  local prompt="$1"
  local output_file="$2"
  local model="${3:-qwen-plus}"

  local result
  result=$(qwen_call "$prompt" "$model")
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "[qwen_call] Failed to get response for: $output_file" >&2
    return 1
  fi

  # Write response to file
  echo "$result" > "$output_file"
  echo "[qwen_call] Written $(wc -l < "$output_file" | tr -d ' ') lines to $output_file"
  return 0
}

# ── Multi-file response writer ───────────────────────────────────
# Parses ===FILE: path=== ... ===ENDFILE=== blocks from response
# and writes each block to the corresponding file.
# Falls back to writing entire response to $base_dir/agent_output.md if no markers found.
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
    # No markers — write whole response as single file
    fallback = os.path.join(base_dir, 'agent_output.md')
    with open(fallback, 'w') as f:
        f.write(response.strip() + '\n')
    print(f'[qwen_write] No markers found, wrote to: {fallback}')

print(f'[qwen_write] Total files written: {files_written}')
PYEOF
}

# ── Run agent with Qwen (full dual-path pattern) ─────────────────
# Usage: run_with_model "$PROMPT" "$MODEL" "$PROJECT_DIR" "$STATE_FILE" "phase_key" "value"
# Handles Qwen API call + file parsing, OR Claude CLI fallback.
run_with_model() {
  local prompt="$1"
  local model="$2"
  local project_dir="$3"
  local state_file="$4"
  local state_key="${5:-}"    # e.g., "research_completed"
  local state_val="${6:-true}" # value to set

  local backend
  backend=$(get_backend "$model")

  if [ "$backend" = "qwen" ]; then
    echo "[agent] Using Qwen: $model"
    local tmp_response
    tmp_response=$(mktemp /tmp/qwen_response.XXXXXX)

    if qwen_call "$prompt" "$model" > "$tmp_response" 2>/dev/null; then
      # Parse and write files from response
      qwen_write_files "$tmp_response" "$project_dir"

      # Update state.json if state_key provided
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
      echo "[agent] Qwen failed. Falling back to Claude Haiku."
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

# ── Token usage tracker ──────────────────────────────────────────
qwen_extract_usage() {
  local response="$1"
  python3 -c "
import json, sys
try:
    data = json.loads('''$response''')
    usage = data.get('usage', {})
    input_t = usage.get('prompt_tokens', 0)
    output_t = usage.get('completion_tokens', 0)
    print(f'{input_t}|{output_t}')
except:
    print('0|0')
" 2>/dev/null
}
