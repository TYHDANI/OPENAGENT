#!/usr/bin/env bash
# OPENAGENT — Brave Search API Integration
# Provides web search and app research capabilities for agents.
#
# Usage:
#   source "$ROOT_DIR/orchestrator/brave_search.sh"
#   results=$(brave_web_search "best iOS productivity apps 2026")
#   results=$(brave_app_research "habit tracker iOS")
#   results=$(brave_market_research "dental AI apps market size")

# ── API Keys (rotate between two for rate limit resilience) ────────
BRAVE_KEY_1="${BRAVE_API_KEY_1:-}"
BRAVE_KEY_2="${BRAVE_API_KEY_2:-}"
BRAVE_ENDPOINT="https://api.search.brave.com/res/v1/web/search"

# Track which key to use (alternate to spread rate limits)
_BRAVE_KEY_INDEX=0

_get_brave_key() {
  if [ $((_BRAVE_KEY_INDEX % 2)) -eq 0 ]; then
    echo "$BRAVE_KEY_1"
  else
    echo "$BRAVE_KEY_2"
  fi
  _BRAVE_KEY_INDEX=$((_BRAVE_KEY_INDEX + 1))
}

# ── Core Search Function ───────────────────────────────────────────
brave_web_search() {
  local query="$1"
  local count="${2:-10}"
  local key
  key=$(_get_brave_key)

  local encoded_query
  encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))")

  local response
  response=$(curl -s --compressed -H "Accept: application/json" \
    -H "Accept-Encoding: gzip" \
    -H "X-Subscription-Token: $key" \
    "$BRAVE_ENDPOINT?q=$encoded_query&count=$count" 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo '{"error": "Brave API request failed", "results": []}'
    return 1
  fi

  # Extract and format results
  echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = []
    for r in data.get('web', {}).get('results', [])[:$count]:
        results.append({
            'title': r.get('title', ''),
            'url': r.get('url', ''),
            'description': r.get('description', ''),
            'age': r.get('age', '')
        })
    print(json.dumps({'results': results, 'count': len(results)}, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e), 'results': []}))
" 2>/dev/null || echo '{"error": "parse failed", "results": []}'
}

# ── App Store Research (search for iOS app opportunities) ──────────
brave_app_research() {
  local topic="$1"
  local results=""

  # Search 1: Direct app search
  local apps
  apps=$(brave_web_search "$topic iOS app site:apps.apple.com" 5)

  # Search 2: Reddit pain points
  local reddit
  reddit=$(brave_web_search "$topic site:reddit.com 'I wish' OR 'there should be' OR 'why isn't there'" 5)

  # Search 3: Market analysis
  local market
  market=$(brave_web_search "$topic app market size revenue 2025 2026" 5)

  # Combine results
  python3 -c "
import json
apps = json.loads('''$apps''') if '''$apps''' else {'results': []}
reddit = json.loads('''$reddit''') if '''$reddit''' else {'results': []}
market = json.loads('''$market''') if '''$market''' else {'results': []}
combined = {
    'topic': '$topic',
    'app_store_results': apps.get('results', []),
    'reddit_signals': reddit.get('results', []),
    'market_data': market.get('results', []),
    'total_signals': len(apps.get('results', [])) + len(reddit.get('results', [])) + len(market.get('results', []))
}
print(json.dumps(combined, indent=2))
" 2>/dev/null || echo '{"error": "combine failed"}'
}

# ── Market Research (deeper dive for validation) ───────────────────
brave_market_research() {
  local query="$1"

  # Search for market data, revenue figures, growth rates
  local market
  market=$(brave_web_search "$query market size TAM revenue growth 2026" 8)

  # Search for competitor analysis
  local competitors
  competitors=$(brave_web_search "$query competitors alternatives comparison iOS" 5)

  python3 -c "
import json
market = json.loads('''$market''') if '''$market''' else {'results': []}
competitors = json.loads('''$competitors''') if '''$competitors''' else {'results': []}
combined = {
    'query': '$query',
    'market_intelligence': market.get('results', []),
    'competitor_landscape': competitors.get('results', []),
    'total_sources': len(market.get('results', [])) + len(competitors.get('results', []))
}
print(json.dumps(combined, indent=2))
" 2>/dev/null || echo '{"error": "market research failed"}'
}

# ── Trending App Ideas Search ──────────────────────────────────────
brave_trending_ideas() {
  local category="${1:-productivity}"

  # Search for trending app ideas and unmet needs
  local trends
  trends=$(brave_web_search "trending $category iOS app ideas 2026 underserved niche" 8)

  # Search Product Hunt for recent launches
  local producthunt
  producthunt=$(brave_web_search "$category app site:producthunt.com 2026" 5)

  python3 -c "
import json
trends = json.loads('''$trends''') if '''$trends''' else {'results': []}
producthunt = json.loads('''$producthunt''') if '''$producthunt''' else {'results': []}
combined = {
    'category': '$category',
    'trends': trends.get('results', []),
    'producthunt_launches': producthunt.get('results', []),
    'total_signals': len(trends.get('results', [])) + len(producthunt.get('results', []))
}
print(json.dumps(combined, indent=2))
" 2>/dev/null || echo '{"error": "trending search failed"}'
}
