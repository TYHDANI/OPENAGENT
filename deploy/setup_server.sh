#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# OPENAGENT + Fortress Capital — Hetzner VPS Deployment Script
# Server: 46.225.233.219 (Ubuntu 24.04, 4 vCPU, 8GB RAM)
#
# Run this AFTER ssh'ing into the server:
#   ssh root@46.225.233.219
#   bash setup_server.sh
#
# What this script does:
#   1. System setup (apt packages, Python 3.11, Node 20)
#   2. Creates 'deploy' user (non-root)
#   3. Clones OPENAGENT + NFTS repos
#   4. Installs Python/Node dependencies
#   5. Creates systemd services:
#      - openagent-orchestrator (littlegreenman every 5 min)
#      - openagent-dashboard (port 8420)
#      - fortress-engine (FastAPI on port 8080, 4 trading bots)
#   6. Configures UFW firewall (SSH, 8420, 8080)
#   7. Sets up log rotation
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Verify running as root ────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  err "Must run as root. Use: sudo bash setup_server.sh"
fi

log "Starting OPENAGENT + Fortress deployment..."
log "Server: $(hostname) | $(uname -r) | $(nproc) vCPU | $(free -h | awk '/Mem:/ {print $2}') RAM"

# ═══════════════════════════════════════════════════════════════════
# STEP 1: System packages
# ═══════════════════════════════════════════════════════════════════
log "Step 1/7: Installing system packages..."

apt-get update -qq
apt-get install -y -qq \
  build-essential git curl wget unzip jq \
  software-properties-common \
  ufw fail2ban \
  supervisor logrotate \
  ca-certificates gnupg lsb-release

# Python 3.12 (default on Ubuntu 24.04) or add deadsnakes for 3.11+
if ! command -v python3 &>/dev/null; then
  apt-get install -y -qq python3 python3-venv python3-dev python3-pip
else
  apt-get install -y -qq python3-venv python3-dev python3-pip 2>/dev/null || true
fi
PYTHON_CMD=$(command -v python3)
log "Python: $($PYTHON_CMD --version)"

# Node 20 via nodesource
if ! command -v node &>/dev/null || ! node --version | grep -q "v20"; then
  log "Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi

log "Python: $($PYTHON_CMD --version) | Node: $(node --version) | npm: $(npm --version)"

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Create deploy user
# ═══════════════════════════════════════════════════════════════════
log "Step 2/7: Setting up deploy user..."

DEPLOY_USER="deploy"
DEPLOY_HOME="/home/$DEPLOY_USER"

if ! id "$DEPLOY_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
  log "Created user: $DEPLOY_USER"
else
  log "User $DEPLOY_USER already exists"
fi

# Copy SSH keys from root to deploy user
mkdir -p "$DEPLOY_HOME/.ssh"
if [ -f /root/.ssh/authorized_keys ]; then
  cp /root/.ssh/authorized_keys "$DEPLOY_HOME/.ssh/authorized_keys"
fi
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_HOME/.ssh"
chmod 700 "$DEPLOY_HOME/.ssh"
chmod 600 "$DEPLOY_HOME/.ssh/authorized_keys" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Clone repositories
# ═══════════════════════════════════════════════════════════════════
log "Step 3/7: Cloning repositories..."

OPENAGENT_DIR="$DEPLOY_HOME/OPENAGENT"
NFTS_DIR="$DEPLOY_HOME/NFTS"

# Clone OPENAGENT
if [ -d "$OPENAGENT_DIR" ]; then
  log "OPENAGENT already exists, pulling latest..."
  su - "$DEPLOY_USER" -c "cd $OPENAGENT_DIR && git pull origin main" || true
else
  su - "$DEPLOY_USER" -c "git clone https://github.com/TYHDANI/OPENAGENT.git $OPENAGENT_DIR"
fi

# Clone Fortress (NFTS)
if [ -d "$NFTS_DIR" ]; then
  log "NFTS already exists, pulling latest..."
  su - "$DEPLOY_USER" -c "cd $NFTS_DIR && git pull origin main" || true
else
  su - "$DEPLOY_USER" -c "git clone https://github.com/TYHDANI/NFTS.git $NFTS_DIR"
fi

# Create required directories
su - "$DEPLOY_USER" -c "mkdir -p $OPENAGENT_DIR/logs $OPENAGENT_DIR/ideas $OPENAGENT_DIR/projects"

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Install dependencies
# ═══════════════════════════════════════════════════════════════════
log "Step 4/7: Installing dependencies..."

# OPENAGENT dependencies (dashboard)
if [ -f "$OPENAGENT_DIR/dashboard/requirements.txt" ]; then
  su - "$DEPLOY_USER" -c "cd $OPENAGENT_DIR/dashboard && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
else
  su - "$DEPLOY_USER" -c "cd $OPENAGENT_DIR/dashboard && python3 -m venv .venv && .venv/bin/pip install flask"
  log "No requirements.txt for dashboard — installed flask"
fi

# Fortress engine dependencies
FORTRESS_ENGINE="$NFTS_DIR/packages/engine"
if [ -d "$FORTRESS_ENGINE" ]; then
  if [ -f "$FORTRESS_ENGINE/requirements.txt" ]; then
    su - "$DEPLOY_USER" -c "cd $FORTRESS_ENGINE && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
  elif [ -f "$FORTRESS_ENGINE/pyproject.toml" ]; then
    su - "$DEPLOY_USER" -c "cd $FORTRESS_ENGINE && python3 -m venv .venv && .venv/bin/pip install -e ."
  fi
  log "Fortress engine dependencies installed"
fi

# Install Claude Code CLI (for agent execution)
if ! command -v claude &>/dev/null; then
  log "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code 2>/dev/null || warn "Claude CLI install failed — agents need this"
fi

# ═══════════════════════════════════════════════════════════════════
# STEP 5: Environment variables
# ═══════════════════════════════════════════════════════════════════
log "Step 5/7: Setting up environment..."

ENV_FILE="$DEPLOY_HOME/.env.openagent"

# Only create if doesn't exist (don't overwrite existing secrets)
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" << 'ENVEOF'
# ── OPENAGENT Environment Variables ──
# Fill in your actual API keys here.

# Anthropic (Claude API)
ANTHROPIC_API_KEY=YOUR_KEY_HERE

# Brave Search (2 keys for rotation)
BRAVE_API_KEY_1=YOUR_KEY_HERE
BRAVE_API_KEY_2=YOUR_KEY_HERE

# Qwen (DashScope) — FREE for cheap phases
DASHSCOPE_API_KEY=YOUR_KEY_HERE

# ── Fortress Trading Engine ──
ALPACA_API_KEY=YOUR_KEY_HERE
ALPACA_SECRET_KEY=YOUR_KEY_HERE
ALPACA_BASE_URL=https://paper-api.alpaca.markets

# Polygon.io market data
POLYGON_API_KEY=YOUR_KEY_HERE

# CoinGecko
COINGECKO_API_KEY=YOUR_KEY_HERE

# Prediction markets
POLYMARKET_API_KEY=YOUR_KEY_HERE
KALSHI_API_KEY=YOUR_KEY_HERE

# AI models for trading intelligence
OPENAI_API_KEY=YOUR_KEY_HERE

# Apify (web scraping for intelligence feeds)
APIFY_API_KEY=YOUR_KEY_HERE
ENVEOF

  chown "$DEPLOY_USER:$DEPLOY_USER" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  warn "Created $ENV_FILE — YOU MUST edit this file with real API keys!"
  warn "Run: nano $ENV_FILE"
else
  log "Environment file already exists at $ENV_FILE"
fi

# ═══════════════════════════════════════════════════════════════════
# STEP 6: Systemd services
# ═══════════════════════════════════════════════════════════════════
log "Step 6/7: Creating systemd services..."

# ── OPENAGENT Orchestrator (runs every 5 min via systemd timer) ──
cat > /etc/systemd/system/openagent-orchestrator.service << EOF
[Unit]
Description=OPENAGENT Orchestrator (littlegreenman)
After=network.target

[Service]
Type=oneshot
User=$DEPLOY_USER
WorkingDirectory=$OPENAGENT_DIR
EnvironmentFile=$ENV_FILE
ExecStart=/bin/bash $OPENAGENT_DIR/orchestrator/littlegreenman.sh
StandardOutput=append:$OPENAGENT_DIR/logs/cron.log
StandardError=append:$OPENAGENT_DIR/logs/cron.log
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/openagent-orchestrator.timer << EOF
[Unit]
Description=Run OPENAGENT orchestrator every 5 minutes

[Timer]
OnBootSec=60
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ── OPENAGENT Dashboard (port 8420) ──
cat > /etc/systemd/system/openagent-dashboard.service << EOF
[Unit]
Description=OPENAGENT Dashboard (port 8420)
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$OPENAGENT_DIR/dashboard
EnvironmentFile=$ENV_FILE
Environment=PORT=8420
ExecStart=$OPENAGENT_DIR/dashboard/.venv/bin/python server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ── Fortress Trading Engine (port 8080) ──
cat > /etc/systemd/system/fortress-engine.service << EOF
[Unit]
Description=Fortress Capital Trading Engine (port 8080)
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$FORTRESS_ENGINE
EnvironmentFile=$ENV_FILE
ExecStart=$FORTRESS_ENGINE/.venv/bin/python run_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ── Fortress Paper Trading (4 bots) ──
cat > /etc/systemd/system/fortress-paper-trade.service << EOF
[Unit]
Description=Fortress Paper Trading Bots (4 strategies)
After=fortress-engine.service
Requires=fortress-engine.service

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$FORTRESS_ENGINE
EnvironmentFile=$ENV_FILE
ExecStart=$FORTRESS_ENGINE/.venv/bin/python scripts/live_paper_trade.py
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable all services
systemctl daemon-reload
systemctl enable openagent-orchestrator.timer
systemctl enable openagent-dashboard
systemctl enable fortress-engine
systemctl enable fortress-paper-trade

log "Systemd services created and enabled"

# ═══════════════════════════════════════════════════════════════════
# STEP 7: Firewall + Security
# ═══════════════════════════════════════════════════════════════════
log "Step 7/7: Configuring firewall..."

# UFW setup
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 8420/tcp comment "OPENAGENT Dashboard"
ufw allow 8080/tcp comment "Fortress Trading Engine"

# Enable UFW (non-interactive)
echo "y" | ufw enable

# Fail2ban for SSH brute-force protection
systemctl enable fail2ban
systemctl start fail2ban

log "Firewall configured: SSH + 8420 + 8080"

# ── Log rotation ─────────────────────────────────────────────────
cat > /etc/logrotate.d/openagent << EOF
$OPENAGENT_DIR/logs/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    copytruncate
}
EOF

# ═══════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN} DEPLOYMENT COMPLETE ${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Edit API keys:"
echo "   nano $ENV_FILE"
echo ""
echo "2. Start all services:"
echo "   systemctl start openagent-orchestrator.timer"
echo "   systemctl start openagent-dashboard"
echo "   systemctl start fortress-engine"
echo "   systemctl start fortress-paper-trade"
echo ""
echo "3. Check status:"
echo "   systemctl status openagent-orchestrator.timer"
echo "   systemctl status openagent-dashboard"
echo "   systemctl status fortress-engine"
echo "   systemctl status fortress-paper-trade"
echo ""
echo "4. View logs:"
echo "   journalctl -u openagent-dashboard -f"
echo "   journalctl -u fortress-engine -f"
echo "   tail -f $OPENAGENT_DIR/logs/cron.log"
echo ""
echo "5. Access:"
echo "   Dashboard: http://46.225.233.219:8420"
echo "   Fortress:  http://46.225.233.219:8080"
echo ""
echo "═══════════════════════════════════════════════════════════════"
