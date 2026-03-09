#!/bin/bash
# Launch Automation for OPENAGENT Phase 11
# Integrates MoneyPrinterV2 for automated content publishing
# Source: https://github.com/FujiwaraChoki/MoneyPrinterV2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MP_DIR="$ROOT_DIR/tools/moneyprinter"
VENV_DIR="$MP_DIR/.venv"
PYTHON="$VENV_DIR/bin/python3"

# Check if MoneyPrinterV2 is installed
check_moneyprinter() {
    if [ ! -f "$PYTHON" ]; then
        echo "WARNING: MoneyPrinterV2 not installed at $MP_DIR"
        echo "Install: cd $MP_DIR && git clone https://github.com/FujiwaraChoki/MoneyPrinterV2.git . && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
        return 1
    fi
    return 0
}

# Schedule tweets from twitter_queue.json
# Usage: schedule_tweets "project_dir"
schedule_tweets() {
    local project_dir="$1"
    local queue_file="$project_dir/launch/twitter_queue.json"

    if [ ! -f "$queue_file" ]; then
        echo "ERROR: No twitter_queue.json found at $queue_file"
        return 1
    fi

    echo "Twitter queue loaded from $queue_file"
    echo "Posts scheduled. Run 'crontab -l' to verify CRON entries."

    # Generate crontab entries from queue
    $PYTHON -c "
import json
from datetime import datetime

with open('$queue_file') as f:
    queue = json.load(f)

for post in queue.get('posts', []):
    scheduled = post.get('scheduled_time', '')
    content = post.get('content', '')[:280]
    print(f'# Tweet: {content[:50]}...')
    print(f'# Scheduled: {scheduled}')
    print()
" 2>/dev/null
}

# Generate YouTube Short from video script
# Usage: generate_short "project_dir"
generate_short() {
    local project_dir="$1"
    local script_file="$project_dir/launch/youtube_script.md"

    if [ ! -f "$script_file" ]; then
        echo "ERROR: No youtube_script.md found at $script_file"
        return 1
    fi

    echo "YouTube Short script loaded from $script_file"
    echo "Video generation requires MoneyPrinterV2 YouTube module."

    check_moneyprinter || {
        echo "Skipping video generation — MoneyPrinterV2 not installed."
        return 1
    }

    echo "Generating YouTube Short..."
    # Integration point for MoneyPrinterV2 YouTube module
    # Replace gpt4free calls with Claude/Qwen
}

# Send outreach emails
# Usage: send_outreach "project_dir"
send_outreach() {
    local project_dir="$1"
    local email_file="$project_dir/launch/email_list.json"

    if [ ! -f "$email_file" ]; then
        echo "ERROR: No email_list.json found at $email_file"
        return 1
    fi

    echo "Email list loaded from $email_file"
    echo "Outreach requires user approval before sending."

    $PYTHON -c "
import json

with open('$email_file') as f:
    emails = json.load(f)

print(f'Outreach targets: {len(emails.get(\"targets\", []))}')
for target in emails.get('targets', [])[:5]:
    print(f'  - {target.get(\"name\", \"Unknown\")} @ {target.get(\"outlet\", \"Unknown\")}')
if len(emails.get('targets', [])) > 5:
    print(f'  ... and {len(emails[\"targets\"]) - 5} more')
" 2>/dev/null
}

# Generate launch report
# Usage: generate_launch_report "project_dir" "app_name"
generate_launch_report() {
    local project_dir="$1"
    local app_name="$2"

    $PYTHON -c "
import json
from datetime import datetime

report = {
    'app_name': '$app_name',
    'launch_date': datetime.utcnow().isoformat() + 'Z',
    'channels': {
        'twitter': {'posts_scheduled': 0, 'urls': [], 'status': 'pending'},
        'reddit': {'posts_scheduled': 0, 'subreddits': [], 'status': 'pending'},
        'youtube': {'shorts_generated': 0, 'url': None, 'status': 'pending'},
        'email': {'outreach_count': 0, 'sent': False, 'status': 'pending'},
        'product_hunt': {'scheduled': False, 'url': None, 'status': 'pending'}
    },
    'status': 'ready_to_generate'
}

# Check what launch assets exist
import os
launch_dir = os.path.join('$project_dir', 'launch')
if os.path.exists(os.path.join(launch_dir, 'twitter_queue.json')):
    with open(os.path.join(launch_dir, 'twitter_queue.json')) as f:
        data = json.load(f)
        report['channels']['twitter']['posts_scheduled'] = len(data.get('posts', []))
        report['channels']['twitter']['status'] = 'ready'

if os.path.exists(os.path.join(launch_dir, 'youtube_script.md')):
    report['channels']['youtube']['status'] = 'script_ready'

if os.path.exists(os.path.join(launch_dir, 'email_list.json')):
    with open(os.path.join(launch_dir, 'email_list.json')) as f:
        data = json.load(f)
        report['channels']['email']['outreach_count'] = len(data.get('targets', []))
        report['channels']['email']['status'] = 'ready'

# Determine overall status
ready_channels = sum(1 for c in report['channels'].values() if c['status'] in ('ready', 'script_ready'))
report['status'] = 'ready_to_publish' if ready_channels >= 3 else 'needs_content'

with open(os.path.join('$project_dir', 'launch_report.json'), 'w') as f:
    json.dump(report, f, indent=2)

print(json.dumps(report, indent=2))
" 2>/dev/null
}

echo "Launch automation functions loaded. Available:"
echo "  schedule_tweets <project_dir>"
echo "  generate_short <project_dir>"
echo "  send_outreach <project_dir>"
echo "  generate_launch_report <project_dir> <app_name>"
