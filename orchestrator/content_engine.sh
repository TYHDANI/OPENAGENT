#!/usr/bin/env bash
# OPENAGENT Content Engine — Larry-Style Autonomous Posting
# Generates content, uploads as drafts, tracks analytics, self-learns
#
# Usage: bash content_engine.sh <project_dir> <action>
# Actions: generate | post | analyze | learn

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load API keys
ENV_FILE="$HOME/.env.openagent"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

PROJECT_DIR="${1:?Usage: content_engine.sh <project_dir> <action>}"
ACTION="${2:-generate}"
APP_NAME=$(python3 -c "import json; print(json.load(open('$PROJECT_DIR/state.json')).get('name','unknown'))" 2>/dev/null)

CONTENT_DIR="$PROJECT_DIR/content"
RULES_FILE="$CONTENT_DIR/RULES.md"
LEARNINGS_FILE="$CONTENT_DIR/LEARNINGS.md"
ANALYTICS_FILE="$CONTENT_DIR/analytics.jsonl"
POST_QUEUE="$CONTENT_DIR/post_queue.json"

mkdir -p "$CONTENT_DIR"

# ── Initialize rules file if missing ─────────────────────────────
init_rules() {
  if [ ! -f "$RULES_FILE" ]; then
    cat > "$RULES_FILE" << 'RULES_EOF'
# Content Rules — Self-Learning File
# This file is updated automatically based on post performance.
# Rules are cumulative — the engine reads ALL rules before generating.

## Hook Formulas (Ranked by Performance)

### Formula 1: Third-Party Conflict (PROVEN — avg 50K+ views)
- Structure: "[Person] said [doubt about app] → showed them → [reaction]"
- Examples:
  - "My boss said no app could handle our HVAC fleet..."
  - "My accountant laughed when I said I track crypto taxes on my phone..."
  - "My trainer didn't believe a watch could track HRV this accurately..."

### Formula 2: Before/After Transformation
- Structure: "I used to [pain point]. Then I found [app]. Now I [result]."
- Best for: productivity, health, finance apps

### Formula 3: Secret/Discovery Hook
- Structure: "I found an app that [unexpected capability] and it's only $X/month"
- Best for: niche/specialized apps

## Content Rules

1. NEVER use generic hooks like "Check out my app" or "Download now"
2. Lead with the PROBLEM, not the product
3. Captions should be storytelling format: Hook → Problem → Discovery → Result
4. Max 5 hashtags per post
5. Always include a soft CTA ("link in bio" or "DM me for details")
6. Post at peak hours: 7-9 AM, 12-1 PM, 6-8 PM user's timezone
7. Slideshow format: 6 slides, portrait (1080x1920)
8. Slide 1 = big hook text, Slides 2-5 = feature showcase, Slide 6 = CTA

## Platform-Specific Rules

### TikTok
- Draft posting only (human adds trending audio)
- Slideshow > video for app content
- Hook must grab in first 2 seconds

### Instagram
- Reels + carousel posts
- Carousel: 10 slides max, educational format
- Stories: behind-the-scenes, polls, questions

### Twitter/X
- Thread format for launches (5-7 tweets)
- Single tweets: hook + screenshot + CTA
- Quote-tweet relevant conversations in niche

### Reddit
- NEVER promotional — value-first, story-driven
- "I built this" format in relevant subreddits
- Engage genuinely in comments

## Retired Approaches (DO NOT USE)
- None yet (will be populated by analytics)

## Performance Thresholds
- Good post: >10K views OR >100 engagements
- Great post: >50K views OR >500 engagements
- Viral post: >100K views OR >1K engagements
- Underperformer: <1K views AND <10 engagements → log and learn
RULES_EOF
    echo "[content_engine] Initialized rules file for $APP_NAME"
  fi
}

# ── Initialize learnings file ────────────────────────────────────
init_learnings() {
  if [ ! -f "$LEARNINGS_FILE" ]; then
    cat > "$LEARNINGS_FILE" << 'LEARN_EOF'
# Content Learnings — Auto-Updated
# Updated after each analytics cycle. DO NOT manually edit.

## Post Performance Log
| Date | Platform | Hook Type | Views | Engagements | Conversions | Grade |
|------|----------|-----------|-------|-------------|-------------|-------|

## Winning Patterns
- (none yet — will be populated after first analytics cycle)

## Failed Patterns
- (none yet)

## Hook A/B Test Results
- (none yet)

## Conversion Funnel Notes
- (none yet)
LEARN_EOF
  fi
}

# ── Generate content batch ───────────────────────────────────────
generate_content() {
  echo "[content_engine] Generating content batch for $APP_NAME..."

  # Read app context
  local one_pager=""
  if [ -f "$PROJECT_DIR/one_pager.md" ]; then
    one_pager=$(head -100 "$PROJECT_DIR/one_pager.md")
  fi

  local promo_posts=""
  if [ -f "$PROJECT_DIR/promo/social_posts.md" ]; then
    promo_posts=$(cat "$PROJECT_DIR/promo/social_posts.md")
  fi

  # Read current rules
  local rules=$(cat "$RULES_FILE" 2>/dev/null || echo "No rules yet")

  # Read learnings
  local learnings=$(cat "$LEARNINGS_FILE" 2>/dev/null || echo "No learnings yet")

  # Generate content via Claude
  local prompt="You are a viral content strategist for the app '$APP_NAME'.

## App Context:
$one_pager

## Existing Promo Content:
$promo_posts

## Content Rules (MUST follow):
$rules

## Learnings From Past Posts:
$learnings

## Task:
Generate a batch of 7 posts (one per day for the week). For each post, output JSON:

{
  \"posts\": [
    {
      \"day\": 1,
      \"platform\": \"tiktok|instagram|twitter|reddit\",
      \"hook_formula\": \"which formula from rules\",
      \"hook_text\": \"the actual hook\",
      \"caption\": \"full caption with storytelling format\",
      \"hashtags\": [\"tag1\", \"tag2\"],
      \"slide_descriptions\": [\"slide 1 desc\", \"slide 2 desc\", ...],
      \"cta\": \"call to action\",
      \"post_time\": \"HH:MM\",
      \"ab_variant\": \"A or B\"
    }
  ]
}

Requirements:
- Mix platforms across the week (2 TikTok, 2 Instagram, 2 Twitter, 1 Reddit)
- Use different hook formulas to A/B test
- Each post tells a STORY, never directly sells
- Reddit post must be authentic 'I built this' format
- Include 2 A/B variants for Day 1 to test hooks

Output ONLY valid JSON, no markdown fences."

  # Use Claude CLI to generate
  echo "$prompt" | claude --print --model claude-sonnet-4-6 2>/dev/null > "$CONTENT_DIR/batch_$(date +%Y%m%d).json" || {
    echo "[content_engine] Failed to generate content batch"
    return 1
  }

  echo "[content_engine] Content batch generated: $CONTENT_DIR/batch_$(date +%Y%m%d).json"
}

# ── Post to platforms via Postiz (or queue for manual) ───────────
post_content() {
  local today=$(date +%u) # 1=Monday, 7=Sunday
  local batch_file=$(ls -t "$CONTENT_DIR"/batch_*.json 2>/dev/null | head -1)

  if [ -z "$batch_file" ]; then
    echo "[content_engine] No content batch found. Run 'generate' first."
    return 1
  fi

  echo "[content_engine] Queuing day $today content from $batch_file..."

  # Extract today's post
  python3 -c "
import json, sys
try:
    with open('$batch_file') as f:
        data = json.load(f)
    posts = data.get('posts', [])
    today_post = [p for p in posts if p.get('day') == $today]
    if today_post:
        # Queue for posting
        queue_file = '$POST_QUEUE'
        try:
            with open(queue_file) as f:
                queue = json.load(f)
        except:
            queue = {'queued': [], 'posted': []}
        queue['queued'].extend(today_post)
        with open(queue_file, 'w') as f:
            json.dump(queue, f, indent=2)
        print(f'Queued {len(today_post)} post(s) for today')
        for p in today_post:
            print(f'  Platform: {p[\"platform\"]} | Hook: {p[\"hook_text\"][:60]}...')
    else:
        print(f'No posts scheduled for day {$today}')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# ── Analyze post performance ─────────────────────────────────────
analyze_performance() {
  echo "[content_engine] Analyzing content performance for $APP_NAME..."

  # Check if we have posted content to analyze
  if [ ! -f "$POST_QUEUE" ]; then
    echo "[content_engine] No post queue found. Nothing to analyze yet."
    return 0
  fi

  # Log analytics entry
  python3 -c "
import json
from datetime import datetime, timezone

queue_file = '$POST_QUEUE'
analytics_file = '$ANALYTICS_FILE'

try:
    with open(queue_file) as f:
        queue = json.load(f)
except:
    queue = {'queued': [], 'posted': []}

posted = queue.get('posted', [])
if not posted:
    print('[content_engine] No posted content to analyze yet.')
else:
    # Generate analytics summary
    total_posts = len(posted)
    platforms = {}
    for p in posted:
        plat = p.get('platform', 'unknown')
        platforms[plat] = platforms.get(plat, 0) + 1

    entry = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'app': '$APP_NAME',
        'total_posts': total_posts,
        'platforms': platforms,
        'period': 'weekly'
    }

    with open(analytics_file, 'a') as f:
        f.write(json.dumps(entry) + '\n')

    print(f'[content_engine] Logged analytics: {total_posts} posts across {platforms}')
"
}

# ── Self-learning cycle ──────────────────────────────────────────
learn_from_results() {
  echo "[content_engine] Running self-learning cycle for $APP_NAME..."

  if [ ! -f "$ANALYTICS_FILE" ]; then
    echo "[content_engine] No analytics data. Run 'analyze' first."
    return 0
  fi

  local analytics=$(cat "$ANALYTICS_FILE")
  local rules=$(cat "$RULES_FILE")
  local learnings=$(cat "$LEARNINGS_FILE")

  # Use Claude to analyze patterns and update rules
  local prompt="You are a content analytics engine. Analyze post performance and update the rules.

## Current Rules:
$rules

## Current Learnings:
$learnings

## Analytics Data:
$analytics

## Task:
1. Identify which hook formulas performed best/worst
2. Identify which platforms drove the most engagement
3. Identify optimal posting times
4. Update the learnings file with new patterns
5. Suggest rule changes (add new rules, retire bad approaches)

Output a JSON object:
{
  \"new_learnings\": \"markdown text to APPEND to learnings file\",
  \"rule_updates\": [
    {\"action\": \"add|retire\", \"rule\": \"the rule text\"}
  ],
  \"summary\": \"one paragraph summary of findings\"
}

Output ONLY valid JSON."

  echo "$prompt" | claude --print --model claude-haiku-4-5-20251001 2>/dev/null > "$CONTENT_DIR/learning_$(date +%Y%m%d).json" || {
    echo "[content_engine] Learning cycle failed"
    return 1
  }

  # Apply learnings
  python3 -c "
import json

try:
    with open('$CONTENT_DIR/learning_$(date +%Y%m%d).json') as f:
        result = json.load(f)

    # Append to learnings file
    new_learnings = result.get('new_learnings', '')
    if new_learnings:
        with open('$LEARNINGS_FILE', 'a') as f:
            f.write('\n\n## Update $(date +%Y-%m-%d)\n')
            f.write(new_learnings)
        print('[content_engine] Updated learnings file')

    # Log rule updates
    for update in result.get('rule_updates', []):
        action = update.get('action', '')
        rule = update.get('rule', '')
        print(f'  Rule {action}: {rule[:80]}...')

    print(f'Summary: {result.get(\"summary\", \"No summary\")}')
except Exception as e:
    print(f'[content_engine] Learning parse error: {e}')
"
}

# ── Main dispatch ────────────────────────────────────────────────
init_rules
init_learnings

case "$ACTION" in
  generate)  generate_content ;;
  post)      post_content ;;
  analyze)   analyze_performance ;;
  learn)     learn_from_results ;;
  full-cycle)
    generate_content
    post_content
    analyze_performance
    learn_from_results
    ;;
  *)
    echo "Usage: content_engine.sh <project_dir> <generate|post|analyze|learn|full-cycle>"
    exit 1
    ;;
esac
