#!/usr/bin/env bash
# OPENAGENT — Add an app idea to the queue
# Usage: add_idea.sh "App Name"
#        add_idea.sh "App Name" "Brief description of the app"

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IDEAS_DIR="$ROOT_DIR/ideas"

APP_NAME="${1:?Usage: add_idea.sh \"App Name\" [\"Brief description\"]}"
DESCRIPTION="${2:-}"

# Create filename from app name
FILENAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
FILEPATH="$IDEAS_DIR/${FILENAME}.md"

if [ -f "$FILEPATH" ]; then
  echo "Error: Idea file already exists: $FILEPATH"
  exit 1
fi

cat > "$FILEPATH" << EOF
# ${APP_NAME}

## Problem
${DESCRIPTION:-TODO: What problem does this app solve? Who has this problem?}

## Solution
TODO: How does the app solve it? Key features (3-5 bullet points).
-
-
-

## Target Audience
TODO: Who will use this? Age range, demographics, interests.

## Monetization
TODO: How should it make money? (subscription, one-time purchase, freemium)
Suggested price point:

## Competition
TODO: Any known competitors? What makes this different?

## Notes
TODO: Any additional context, inspiration, or requirements.
EOF

echo "Idea created: $FILEPATH"
echo ""
echo "Edit the file to fill in the details, or leave as-is for the research agent to flesh out."
echo "LITTLEGREENMAN will pick it up on the next 5-minute cycle."
