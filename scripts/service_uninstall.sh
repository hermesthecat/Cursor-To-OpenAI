#!/bin/bash

# Cursor To OpenAI - Service Uninstallation Script
echo "=========================================="
echo "  Cursor To OpenAI Service Uninstaller   "
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    echo "   Usage: sudo bash scripts/service_uninstall.sh"
    exit 1
fi

SERVICE_NAME="cursor-to-openai"
SERVICE_USER="cursor-api"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "🔧 Service name: $SERVICE_NAME"

# Check if service exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "⚠️  Service $SERVICE_NAME is not installed"
    exit 1
fi

# Stop the service if running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "🛑 Stopping $SERVICE_NAME service..."
    systemctl stop "$SERVICE_NAME"
else
    echo "ℹ️  Service $SERVICE_NAME is not running"
fi

# Disable the service
echo "🚫 Disabling $SERVICE_NAME service..."
systemctl disable "$SERVICE_NAME"

# Remove service file
echo "🗑️  Removing service file: $SERVICE_FILE"
rm -f "$SERVICE_FILE"

# Reload systemd
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed

# Ask about removing service user
echo ""
read -p "🤔 Do you want to remove the service user '$SERVICE_USER'? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if id "$SERVICE_USER" &>/dev/null; then
        echo "👤 Removing service user: $SERVICE_USER"
        userdel "$SERVICE_USER"
    else
        echo "ℹ️  Service user $SERVICE_USER does not exist"
    fi
else
    echo "ℹ️  Service user $SERVICE_USER kept (can be removed manually with: sudo userdel $SERVICE_USER)"
fi

echo ""
echo "✅ Service $SERVICE_NAME has been uninstalled successfully!"
echo ""
echo "📝 Note: Project files are kept in place"
echo "   You can still run the application manually with: npm start"
echo ""
echo "==========================================" 