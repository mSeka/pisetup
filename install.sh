#!/bin/bash

# One-command Raspberry Pi 5 setup installer
# Downloads and runs the complete setup automatically
# System update and time sync are SKIPPED.

set -e

echo "🚀 Raspberry Pi 5 Auto Setup (Skipping Updates)"
echo "==============================================="
echo "This will:"
echo "  ✅ Switch to X11"
echo "  ✅ Setup auto-dimming (5 second timeout)"
echo "  ✅ Configure autostart on every boot"
echo "  ✅ Hide mouse cursor after inactivity"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Don't run as root. Run as pi user."
    exit 1
fi

echo "📦 Starting setup..."

# --- SKIPPING SYSTEM UPDATE AND TIME SYNC ---
echo "⏩ Skipping system update and time sync as requested."
# --- END SKIPPING ---

# Switch to X11
echo "🖥️  Switching to X11..."
sudo raspi-config nonint do_wayland W1

# Install xprintidle
echo "📋 Installing xprintidle..."
sudo apt install -y xprintidle

# Create auto-dimming script
echo "💡 Setting up auto-dimming (5 second timeout)..."
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
#!/bin/bash
IDLE_TIME_MS=5000 # Changed to 5 seconds
DIM_BRIGHTNESS=51
NORMAL_BRIGHTNESS=255
BACKLIGHT_PATH="/sys/class/backlight/10-0045/brightness" # Corrected path
already_dimmed=0

# Add a small delay to ensure X server is fully up
sleep 5

while true; do
    # Use 2>/dev/null to suppress errors if xprintidle isn't ready
    # Use || echo "999999" to ensure a large number if xprintidle fails
    idle=$(xprintidle 2>/dev/null || echo "999999")
    
    if [ "$idle" -ge "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 0 ]; then
        # Use 2>/dev/null || true to suppress errors if backlight path is wrong or permissions issue
        echo "$DIM_BRIGHTNESS" | sudo tee "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=1
    elif [ "$idle" -lt "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 1 ]; then
        echo "$NORMAL_BRIGHTNESS" | sudo tee "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=0
    fi
    sleep 1
done
EOF

sudo chmod +x /usr/local/bin/auto-dim.sh

# Create systemd service for auto-dimming
echo "⚙️  Creating auto-dimming autostart service..."
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
Environment=XDG_SESSION_TYPE=x11 # Explicitly set XDG_SESSION_TYPE for the service

[Install]
WantedBy=graphical-session.target
EOF

# Enable auto-dimming service for autostart
sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service


# --- ADDING MOUSE CURSOR HIDING ---
echo "🖱️  Setting up mouse cursor hiding..."
sudo apt install -y unclutter

# Add to .xsessionrc for autostart (reliable for graphical sessions)
# Use 'nohup' and '&' to ensure it runs in background and detaches from terminal
echo "nohup unclutter -idle 0 &" >> ~/.xsessionrc

# Also create a desktop entry for more robust autostart in graphical environments
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/unclutter.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Unclutter
Exec=unclutter -idle 0
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
echo "🖱️  Mouse cursor hiding configured."
# --- END MOUSE CURSOR HIDING ---


echo ""
echo "✅ Setup completed successfully!"
echo "✅ Auto-dimming and mouse cursor hiding will start on every boot"
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
