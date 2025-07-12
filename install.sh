#!/bin/bash

# One-command Raspberry Pi 5 setup installer
# Downloads and runs the complete setup automatically

set -e

echo "🚀 Raspberry Pi 5 Auto Setup"
echo "============================"
echo "This will:"
echo "  ✅ Update system (apt update && apt full-upgrade)"
echo "  ✅ Switch to X11"
echo "  ✅ Setup auto-dimming (30 second timeout)"
echo "  ✅ Configure autostart on every boot"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Don't run as root. Run as pi user."
    exit 1
fi

echo "📦 Starting setup..."

# System update
echo "🔄 Updating system packages..."
sudo apt update
sudo apt full-upgrade -y

# Switch to X11
echo "🖥️  Switching to X11..."
sudo raspi-config nonint do_wayland W1

# Install xprintidle
echo "📋 Installing xprintidle..."
sudo apt install -y xprintidle

# Create auto-dimming script
echo "💡 Setting up auto-dimming..."
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
#!/bin/bash
IDLE_TIME_MS=30000
DIM_BRIGHTNESS=51
NORMAL_BRIGHTNESS=255
BACKLIGHT_PATH="/sys/class/backlight/10-0045/brightness"
already_dimmed=0

while true; do
    idle=$(xprintidle 2>/dev/null || echo "999999")
    if [ "$idle" -ge "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 0 ]; then
        echo "$DIM_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=1
    elif [ "$idle" -lt "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 1 ]; then
        echo "$NORMAL_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=0
    fi
    sleep 1
done
EOF

sudo chmod +x /usr/local/bin/auto-dim.sh

# Create systemd service
echo "⚙️  Creating autostart service..."
sudo tee /etc/systemd/system/auto-dim.service > /dev/null << 'EOF'
[Unit]
Description=Auto Dim Display After Inactivity
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/auto-dim.sh
Restart=always
RestartSec=10
User=pi
Environment=DISPLAY=:0

[Install]
WantedBy=graphical-session.target
EOF

# Enable service for autostart
sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service

echo ""
echo "✅ Setup completed successfully!"
echo "✅ Auto-dimming will start on every boot"
echo ""
echo "⚠️  Reboot required for changes to take effect"
echo ""

read -p "Reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "💡 Reboot manually when ready: sudo reboot"
fi
