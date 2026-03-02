#!/bin/bash
# reddit_market_research.sh — Apify Reddit scraper for OPENAGENT market research
# Usage: ./scripts/reddit_market_research.sh
# Requires: curl, python3, jq (optional)
# API Key is embedded; rotate after use if needed.

set -euo pipefail

APIFY_TOKEN="${APIFY_API_KEY:?Set APIFY_API_KEY env var}"
ACTOR="trudax~reddit-scraper-lite"
BASE="https://api.apify.com/v2"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/ideas/raw_reddit_data"
mkdir -p "$OUTPUT_DIR"

echo "=== OPENAGENT Reddit Market Research Scraper ==="
echo "Output: $OUTPUT_DIR"
echo ""

# --- Scrape 1: r/SomebodyMakeThis (top, year) ---
echo "[1/4] Scraping r/SomebodyMakeThis (top posts, past year)..."
RUN1=$(curl -s -X POST "$BASE/acts/$ACTOR/runs?token=$APIFY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startUrls": [
      {"url": "https://www.reddit.com/r/SomebodyMakeThis/top/?t=year"}
    ],
    "maxItems": 80,
    "maxPostCount": 80,
    "maxComments": 5,
    "proxy": {"useApifyProxy": true}
  }')
RUN1_ID=$(echo "$RUN1" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
echo "  Run ID: $RUN1_ID"

# --- Scrape 2: r/AppIdeas (top, year) ---
echo "[2/4] Scraping r/AppIdeas (top posts, past year)..."
RUN2=$(curl -s -X POST "$BASE/acts/$ACTOR/runs?token=$APIFY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startUrls": [
      {"url": "https://www.reddit.com/r/AppIdeas/top/?t=year"}
    ],
    "maxItems": 80,
    "maxPostCount": 80,
    "maxComments": 5,
    "proxy": {"useApifyProxy": true}
  }')
RUN2_ID=$(echo "$RUN2" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
echo "  Run ID: $RUN2_ID"

# --- Scrape 3: Search across Reddit for "wish there was an app" and "would pay for" ---
echo "[3/4] Scraping Reddit search: 'wish there was an app' + 'would pay for'..."
RUN3=$(curl -s -X POST "$BASE/acts/$ACTOR/runs?token=$APIFY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startUrls": [
      {"url": "https://www.reddit.com/search/?q=%22I+wish+there+was+an+app%22&sort=top&t=year"},
      {"url": "https://www.reddit.com/search/?q=%22I+would+pay+for%22+app&sort=top&t=year"},
      {"url": "https://www.reddit.com/search/?q=%22someone+needs+to+build%22+app&sort=top&t=year"}
    ],
    "maxItems": 100,
    "maxPostCount": 100,
    "maxComments": 5,
    "proxy": {"useApifyProxy": true}
  }')
RUN3_ID=$(echo "$RUN3" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
echo "  Run ID: $RUN3_ID"

# --- Scrape 4: Entrepreneur / Freelance / SmallBusiness pain points ---
echo "[4/4] Scraping r/Entrepreneur + r/smallbusiness + r/freelance (pain point posts)..."
RUN4=$(curl -s -X POST "$BASE/acts/$ACTOR/runs?token=$APIFY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "startUrls": [
      {"url": "https://www.reddit.com/r/Entrepreneur/search/?q=%22pain+point%22+OR+%22wish+there+was%22+OR+%22need+an+app%22&sort=top&t=year"},
      {"url": "https://www.reddit.com/r/smallbusiness/search/?q=%22app+for%22+OR+%22software+for%22+OR+%22wish+there+was%22&sort=top&t=year"},
      {"url": "https://www.reddit.com/r/freelance/search/?q=%22wish+there+was%22+OR+%22need+an+app%22+OR+%22tool+for%22&sort=top&t=year"}
    ],
    "maxItems": 100,
    "maxPostCount": 100,
    "maxComments": 5,
    "proxy": {"useApifyProxy": true}
  }')
RUN4_ID=$(echo "$RUN4" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
echo "  Run ID: $RUN4_ID"

echo ""
echo "All 4 scraping runs started. Polling for completion..."

# --- Poll all runs ---
ALL_IDS=("$RUN1_ID" "$RUN2_ID" "$RUN3_ID" "$RUN4_ID")
LABELS=("somebody_make_this" "app_ideas" "wish_search" "entrepreneur_pain")

for i in "${!ALL_IDS[@]}"; do
  RID="${ALL_IDS[$i]}"
  LABEL="${LABELS[$i]}"
  echo -n "  Waiting for $LABEL ($RID)..."
  while true; do
    STATUS=$(curl -s "$BASE/actor-runs/$RID?token=$APIFY_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['status'])")
    if [[ "$STATUS" == "SUCCEEDED" ]]; then
      echo " DONE"
      # Fetch dataset
      DATASET_ID=$(curl -s "$BASE/actor-runs/$RID?token=$APIFY_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['defaultDatasetId'])")
      curl -s "$BASE/datasets/$DATASET_ID/items?token=$APIFY_TOKEN&format=json" > "$OUTPUT_DIR/${LABEL}.json"
      echo "    Saved to $OUTPUT_DIR/${LABEL}.json"
      break
    elif [[ "$STATUS" == "FAILED" || "$STATUS" == "ABORTED" || "$STATUS" == "TIMED-OUT" ]]; then
      echo " $STATUS (skipping)"
      break
    fi
    echo -n "."
    sleep 10
  done
done

echo ""
echo "=== Scraping Complete ==="
echo "Raw data saved to: $OUTPUT_DIR/"
echo "Files:"
ls -la "$OUTPUT_DIR/"
echo ""
echo "Next: Run the analysis script or feed this data to Claude for idea extraction."
