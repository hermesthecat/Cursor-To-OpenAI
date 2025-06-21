#!/bin/bash

# Cursor To OpenAI - Service Installation Script
echo "========================================"
echo "  Cursor To OpenAI Service Installer    "
echo "========================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    echo "   Usage: sudo bash scripts/service_install.sh"
    exit 1
fi

# Get the current directory (project root)
PROJECT_DIR="$(pwd)"
SERVICE_NAME="cursor-to-openai"
SERVICE_USER="cursor-api"

echo "📁 Project directory: $PROJECT_DIR"
echo "🔧 Service name: $SERVICE_NAME"

# Check if .env file exists
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "⚠️  .env file not found in $PROJECT_DIR"
    echo "📝 Please run 'npm run login' first to get your Cursor token"
    exit 1
fi

# Check if CURSOR_TOKEN is set
if ! grep -q "CURSOR_TOKEN=" "$PROJECT_DIR/.env"; then
    echo "⚠️  CURSOR_TOKEN not found in .env file!"
    echo "📝 Please run 'npm run login' to get your Cursor token"
    exit 1
fi

echo "✅ .env file found with CURSOR_TOKEN"

# Create service user if it doesn't exist
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "👤 Creating service user: $SERVICE_USER"
    useradd --system --no-create-home --shell /bin/false "$SERVICE_USER"
else
    echo "✅ Service user $SERVICE_USER already exists"
fi

# Set proper ownership
echo "🔐 Setting file permissions..."
chown -R "$SERVICE_USER:$SERVICE_USER" "$PROJECT_DIR"
chmod +x "$PROJECT_DIR/scripts/start.sh"

# Install Node.js dependencies if needed
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    cd "$PROJECT_DIR"
    sudo -u "$SERVICE_USER" npm install
fi

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
echo "📝 Creating systemd service file: $SERVICE_FILE"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Cursor To OpenAI API Service
Documentation=https://github.com/hermesthecat/Cursor-To-OpenAI
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$PROJECT_DIR
Environment=NODE_ENV=production
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=/usr/bin/node $PROJECT_DIR/src/app.js
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$PROJECT_DIR
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload

echo "🚀 Enabling $SERVICE_NAME service..."
systemctl enable "$SERVICE_NAME"

echo "▶️  Starting $SERVICE_NAME service..."
systemctl start "$SERVICE_NAME"

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ Service installed and started successfully!"
    echo ""
    echo "📋 Service Management Commands:"
    echo "   Start:   sudo systemctl start $SERVICE_NAME"
    echo "   Stop:    sudo systemctl stop $SERVICE_NAME"
    echo "   Restart: sudo systemctl restart $SERVICE_NAME"
    echo "   Status:  sudo systemctl status $SERVICE_NAME"
    echo "   Logs:    sudo journalctl -u $SERVICE_NAME -f"
    echo ""
    echo "🌐 Service is running on: http://localhost:3010"
    echo "🔧 API Models: http://localhost:3010/v1/models"
    echo ""
    echo "🗑️  To uninstall: bash scripts/service_uninstall.sh"
else
    echo "❌ Service failed to start!"
    echo "📋 Check logs: sudo journalctl -u $SERVICE_NAME -n 20"
    exit 1
fi

echo "========================================" 