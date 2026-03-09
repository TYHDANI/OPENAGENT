#!/bin/bash
# Scrapling Integration for OPENAGENT Deep Research (Phase 1)
# Requires: pip install scrapling (in tools/scrapling/.venv)
# Source: https://github.com/D4Vinci/Scrapling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$ROOT_DIR/tools/scrapling/.venv"
PYTHON="$VENV_DIR/bin/python3"

# Check if Scrapling is installed
check_scrapling() {
    if [ ! -f "$PYTHON" ]; then
        echo "ERROR: Scrapling venv not found at $VENV_DIR"
        echo "Install: python3 -m venv $VENV_DIR && $VENV_DIR/bin/pip install scrapling"
        return 1
    fi
    return 0
}

# Scrape App Store listing for a competitor app
# Usage: scrape_app_store "app_name" "app_store_url"
scrape_app_store() {
    local app_name="$1"
    local url="$2"

    check_scrapling || return 1

    $PYTHON -c "
from scrapling import Fetcher
import json

fetcher = Fetcher(auto_match=True)
page = fetcher.get('$url')

data = {
    'name': '$app_name',
    'url': '$url',
    'description': '',
    'rating': '',
    'reviews_count': '',
    'price': '',
    'in_app_purchases': [],
    'screenshots': [],
    'whats_new': '',
    'last_updated': ''
}

# Extract available elements
try:
    desc = page.css_first('.section__description')
    if desc:
        data['description'] = desc.text()[:2000]
except: pass

try:
    rating = page.css_first('.we-star-rating')
    if rating:
        data['rating'] = rating.attrib.get('aria-label', '')
except: pass

print(json.dumps(data, indent=2))
" 2>/dev/null
}

# Scrape Reddit thread for user complaints/feedback
# Usage: scrape_reddit_thread "subreddit" "search_query"
scrape_reddit_thread() {
    local subreddit="$1"
    local query="$2"

    check_scrapling || return 1

    $PYTHON -c "
from scrapling import StealthFetcher
import json

fetcher = StealthFetcher(auto_match=True)
url = f'https://old.reddit.com/r/$subreddit/search?q=$query&restrict_sr=on&sort=relevance&t=year'
page = fetcher.get(url)

posts = []
for post in page.css('.thing.link')[:10]:
    title_el = post.css_first('a.title')
    score_el = post.css_first('.score.unvoted')
    comments_el = post.css_first('.comments')

    if title_el:
        posts.append({
            'title': title_el.text(),
            'url': title_el.attrib.get('href', ''),
            'score': score_el.text() if score_el else '0',
            'comments': comments_el.text() if comments_el else '0'
        })

print(json.dumps(posts, indent=2))
" 2>/dev/null
}

# Scrape competitor reviews from App Store web
# Usage: scrape_reviews "app_store_url"
scrape_reviews() {
    local url="$1"

    check_scrapling || return 1

    $PYTHON -c "
from scrapling import StealthFetcher
import json

fetcher = StealthFetcher(auto_match=True)
page = fetcher.get('$url')

reviews = []
for review in page.css('.we-customer-review')[:20]:
    title = review.css_first('.we-customer-review__title')
    body = review.css_first('.we-customer-review__body')
    rating = review.css_first('.we-star-rating')

    if title or body:
        reviews.append({
            'title': title.text() if title else '',
            'body': body.text()[:500] if body else '',
            'rating': rating.attrib.get('aria-label', '') if rating else ''
        })

print(json.dumps(reviews, indent=2))
" 2>/dev/null
}

# Mine trending topics from multiple sources
# Usage: scrape_trending "category"
scrape_trending() {
    local category="$1"

    check_scrapling || return 1

    $PYTHON -c "
from scrapling import Fetcher
import json

fetcher = Fetcher(auto_match=True)

trends = []

# Product Hunt
try:
    page = fetcher.get('https://www.producthunt.com/topics/$category')
    for item in page.css('.styles_item__Dk5s4')[:10]:
        name = item.css_first('h3')
        desc = item.css_first('p')
        if name:
            trends.append({
                'source': 'producthunt',
                'name': name.text(),
                'description': desc.text() if desc else ''
            })
except: pass

print(json.dumps(trends, indent=2))
" 2>/dev/null
}

echo "Scrapling search functions loaded. Available:"
echo "  scrape_app_store <name> <url>"
echo "  scrape_reddit_thread <subreddit> <query>"
echo "  scrape_reviews <app_store_url>"
echo "  scrape_trending <category>"
