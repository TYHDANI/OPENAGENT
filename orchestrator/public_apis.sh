#!/usr/bin/env bash
# OPENAGENT — Public APIs Catalog Integration
# Searches the public-apis GitHub repo for free APIs relevant to app ideas.
# Used by the research agent to find data sources for app features.
#
# Usage:
#   source "$ROOT_DIR/orchestrator/public_apis.sh"
#   results=$(search_public_apis "weather fitness")
#   results=$(get_apis_by_category "Finance")

# Raw GitHub URL for the public-apis catalog
PUBLIC_APIS_URL="https://raw.githubusercontent.com/public-apis/public-apis/master/README.md"

# Cache the catalog locally (refreshes daily)
_PUBLIC_APIS_CACHE="/tmp/public_apis_cache.md"
_PUBLIC_APIS_CACHE_AGE=86400  # 24 hours

_ensure_public_apis_cache() {
  local need_refresh=true

  if [ -f "$_PUBLIC_APIS_CACHE" ]; then
    local age
    age=$(( $(date +%s) - $(stat -c %Y "$_PUBLIC_APIS_CACHE" 2>/dev/null || stat -f %m "$_PUBLIC_APIS_CACHE" 2>/dev/null || echo 0) ))
    if [ "$age" -lt "$_PUBLIC_APIS_CACHE_AGE" ]; then
      need_refresh=false
    fi
  fi

  if [ "$need_refresh" = true ]; then
    curl -s --max-time 15 "$PUBLIC_APIS_URL" > "$_PUBLIC_APIS_CACHE" 2>/dev/null || true
  fi
}

# ── Search APIs by keyword ────────────────────────────────────────
search_public_apis() {
  local query="$1"
  local max_results="${2:-10}"

  _ensure_public_apis_cache

  if [ ! -f "$_PUBLIC_APIS_CACHE" ] || [ ! -s "$_PUBLIC_APIS_CACHE" ]; then
    echo '{"error": "Could not fetch public-apis catalog", "results": []}'
    return 1
  fi

  python3 -c "
import json, re

query = '''$query'''.lower()
max_results = $max_results
keywords = query.split()

results = []
current_category = ''

with open('$_PUBLIC_APIS_CACHE', 'r') as f:
    for line in f:
        line = line.strip()
        if line.startswith('### '):
            current_category = line.replace('### ', '').strip()
            continue
        if line.startswith('|') and not line.startswith('| API') and '---' not in line:
            parts = [p.strip() for p in line.split('|')[1:-1]]
            if len(parts) >= 3:
                name = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', parts[0])
                desc = parts[1] if len(parts) > 1 else ''
                auth = parts[2] if len(parts) > 2 else ''
                url_match = re.search(r'\[([^\]]+)\]\(([^\)]+)\)', parts[0])
                url = url_match.group(2) if url_match else ''
                text = f'{name} {desc} {current_category}'.lower()
                score = sum(1 for kw in keywords if kw in text)
                if score > 0:
                    results.append({
                        'name': name, 'description': desc,
                        'category': current_category, 'auth': auth,
                        'url': url, 'relevance_score': score,
                        'free': auth.strip().lower() in ('', 'no')
                    })

results.sort(key=lambda x: x['relevance_score'], reverse=True)
print(json.dumps({'query': query, 'results': results[:max_results], 'count': min(len(results), max_results)}, indent=2))
" 2>/dev/null || echo '{"error": "search failed", "results": []}'
}

# ── Get APIs by category ──────────────────────────────────────────
get_apis_by_category() {
  local category="$1"
  local max_results="${2:-15}"

  _ensure_public_apis_cache

  if [ ! -f "$_PUBLIC_APIS_CACHE" ] || [ ! -s "$_PUBLIC_APIS_CACHE" ]; then
    echo '{"error": "Could not fetch public-apis catalog", "results": []}'
    return 1
  fi

  python3 -c "
import json, re

target_cat = '''$category'''.lower()
max_results = $max_results
results = []
current_category = ''
in_target = False

with open('$_PUBLIC_APIS_CACHE', 'r') as f:
    for line in f:
        line = line.strip()
        if line.startswith('### '):
            current_category = line.replace('### ', '').strip()
            in_target = target_cat in current_category.lower()
            continue
        if in_target and line.startswith('|') and not line.startswith('| API') and '---' not in line:
            parts = [p.strip() for p in line.split('|')[1:-1]]
            if len(parts) >= 3:
                name = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', parts[0])
                desc = parts[1] if len(parts) > 1 else ''
                auth = parts[2] if len(parts) > 2 else ''
                url_match = re.search(r'\[([^\]]+)\]\(([^\)]+)\)', parts[0])
                url = url_match.group(2) if url_match else ''
                results.append({
                    'name': name, 'description': desc,
                    'category': current_category, 'auth': auth,
                    'url': url, 'free': auth.strip().lower() in ('', 'no')
                })

print(json.dumps({'category': target_cat, 'results': results[:max_results], 'count': min(len(results), max_results)}, indent=2))
" 2>/dev/null || echo '{"error": "category search failed", "results": []}'
}

# ── List all categories ──────────────────────────────────────────
list_api_categories() {
  _ensure_public_apis_cache

  python3 -c "
import json
categories = []
with open('$_PUBLIC_APIS_CACHE', 'r') as f:
    for line in f:
        if line.strip().startswith('### '):
            categories.append(line.strip().replace('### ', ''))
print(json.dumps({'categories': categories, 'count': len(categories)}, indent=2))
" 2>/dev/null || echo '{"error": "list failed", "categories": []}'
}
