#!/bin/bash

# Script to fix autostart issues if dimming doesn't start on boot

echo "🔧 Fixing auto-dimming autostart..."

# Stop service if running
sudo systemctl stop auto-dim.service 2>/dev/null || true

# Recreate the service with better autostart configuration
sudo tee /etc/systemd/system/auto-dim.service > /dev/null << 'EOF'
[Unit]
Description=Auto Dim Display After Inactivity
After=graphical-session.target
Wants=graphical-session.target
Requisite=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/auto-dim.sh
Restart=always
RestartSec=10
User=pi
Environment=DISPLAY=:0
Environment=XDG_SESSION_TYPE=x11

[Install]
WantedBy=graphical-session.target
EOF

# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service
sudo systemctl start auto-dim.service

echo "✅ Auto-dimming service reconfigured for better autostart"
echo "✅ Service will now start automatically after graphical session loads"

# Check status
if sudo systemctl is-active --quiet auto-dim.service; then
    echo "✅ Service is now running"
else
    echo "⚠️  Service may start after next reboot"
fi
