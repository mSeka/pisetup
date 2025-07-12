#!/bin/bash

# First Boot Setup Script for Raspberry Pi 5
# Place this in /boot/firmware/ and it will run automatically on first boot

# Create log file
exec > >(tee -a /boot/firmware/firstboot-setup.log) 2>&1
echo "=== First Boot Setup Started: $(date) ==="

# Wait for system to be ready
sleep 30

# Update system
echo "Updating system packages..."
apt update
apt full-upgrade -y

# Switch to X11
echo "Switching to X11..."
raspi-config nonint do_wayland W1

# Install xprintidle
echo "Installing xprintidle..."
apt install -y xprintidle

# Create auto-dimming script
echo "Setting up auto-dimming..."
tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
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

chmod +x /usr/local/bin/auto-dim.sh

# Create systemd service
tee /etc/systemd/system/auto-dim.service > /dev/null << 'EOF'
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

# Enable the service
systemctl daemon-reload
systemctl enable auto-dim.service

# Remove this script so it doesn't run again
systemctl disable firstboot-setup.service
rm -f /etc/systemd/system/firstboot-setup.service
rm -f /boot/firmware/firstboot-setup.sh

echo "=== First Boot Setup Completed: $(date) ==="
echo "System will reboot in 10 seconds..."
sleep 10
reboot
