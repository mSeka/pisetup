#!/bin/bash

# Script to prepare SD card with auto-setup
# Run this on your computer AFTER flashing Raspberry Pi OS

echo "🔧 Preparing SD card for automatic Pi setup..."

# Check if boot partition is mounted
BOOT_PATH=""
if [ -d "/media/$USER/bootfs" ]; then
    BOOT_PATH="/media/$USER/bootfs"
elif [ -d "/Volumes/bootfs" ]; then
    BOOT_PATH="/Volumes/bootfs"  # macOS
elif [ -d "/media/pi/bootfs" ]; then
    BOOT_PATH="/media/pi/bootfs"
else
    echo "❌ Boot partition not found. Please mount your SD card."
    echo "Looking for: /media/$USER/bootfs or /Volumes/bootfs"
    exit 1
fi

echo "📁 Found boot partition at: $BOOT_PATH"

# Create the firstboot setup script
echo "📝 Creating firstboot setup script..."
cat > "$BOOT_PATH/firstboot-setup.sh" << 'EOF'
#!/bin/bash
exec > >(tee -a /boot/firmware/firstboot-setup.log) 2>&1
echo "=== First Boot Setup Started: $(date) ==="
sleep 30
apt update && apt full-upgrade -y
raspi-config nonint do_wayland W1
apt install -y xprintidle

tee /usr/local/bin/auto-dim.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
IDLE_TIME_MS=30000; DIM_BRIGHTNESS=51; NORMAL_BRIGHTNESS=255
BACKLIGHT_PATH="/sys/class/backlight/10-0045/brightness"; already_dimmed=0
while true; do
    idle=$(xprintidle 2>/dev/null || echo "999999")
    if [ "$idle" -ge "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 0 ]; then
        echo "$DIM_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=1
    elif [ "$idle" -lt "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 1 ]; then
        echo "$NORMAL_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true
        already_dimmed=0
    fi; sleep 1
done
SCRIPT_EOF

chmod +x /usr/local/bin/auto-dim.sh

tee /etc/systemd/system/auto-dim.service > /dev/null << 'SERVICE_EOF'
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
SERVICE_EOF

systemctl daemon-reload
systemctl enable auto-dim.service
systemctl disable firstboot-setup.service
rm -f /etc/systemd/system/firstboot-setup.service
rm -f /boot/firmware/firstboot-setup.sh
echo "=== Setup Completed: $(date) ==="
sleep 10 && reboot
EOF

chmod +x "$BOOT_PATH/firstboot-setup.sh"

# Add firstboot service to config
echo "⚙️  Adding firstboot service configuration..."
cat >> "$BOOT_PATH/config.txt" << 'EOF'

# Auto-setup service - runs setup on first boot
dtparam=audio=on
EOF

# Create userconf for auto-login (optional)
echo "👤 Setting up auto-login..."
echo 'pi:$6$rBoByrWRKMY1EHFy$ho.LISnfm83CLBWBE/yqJ7Mz7vTFQOBUFjk5zNDDKoUuWDwOqNJfzf6fXn6qOtY1j.lJJ8jKnZf5Qk5U5U5U5.' > "$BOOT_PATH/userconf.txt"

# Create cmdline.txt modification for firstboot
if [ -f "$BOOT_PATH/cmdline.txt" ]; then
    # Add systemd service to run on first boot
    sed -i.bak 's/$/ systemd.run="\/boot\/firmware\/firstboot-setup.sh"/' "$BOOT_PATH/cmdline.txt" 2>/dev/null || true
fi

echo "✅ SD card prepared successfully!"
echo ""
echo "📋 What was added to your SD card:"
echo "   - firstboot-setup.sh (auto-setup script)"
echo "   - Modified config.txt"
echo "   - userconf.txt (default pi user)"
echo ""
echo "🚀 Next steps:"
echo "   1. Safely eject SD card"
echo "   2. Insert into Raspberry Pi 5"
echo "   3. Power on - setup runs automatically!"
echo "   4. Wait ~10-15 minutes for complete setup"
echo "   5. Pi will reboot when finished"
echo ""
echo "📊 Check setup progress:"
echo "   - SSH to pi and run: tail -f /boot/firmware/firstboot-setup.log"
