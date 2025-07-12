#!/bin/bash

# Manual method - copy files to SD card step by step

echo "📋 Manual SD Card Setup Instructions"
echo "=================================="
echo ""
echo "1. Flash Raspberry Pi OS to SD card using Raspberry Pi Imager"
echo "2. After flashing, re-insert SD card (don't eject yet)"
echo "3. Navigate to the boot partition (usually called 'bootfs')"
echo "4. Copy the files as shown below:"
echo ""

echo "🔧 Step 1: Create firstboot-setup.sh"
echo "Create a file called 'firstboot-setup.sh' with this content:"
echo "----------------------------------------"
cat << 'EOF'
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
        echo "$DIM_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true; already_dimmed=1
    elif [ "$idle" -lt "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 1 ]; then
        echo "$NORMAL_BRIGHTNESS" > "$BACKLIGHT_PATH" 2>/dev/null || true; already_dimmed=0
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
echo "=== Setup Completed: $(date) ==="
sleep 10 && reboot
EOF

echo "----------------------------------------"
echo ""
echo "🔧 Step 2: Add to config.txt"
echo "Add these lines to the END of config.txt:"
echo "----------------------------------------"
echo "# Waveshare PI5-HMI-080C Display Configuration"
echo "dtoverlay=vc4-kms-v3d"
echo "dtoverlay=ov5647" 
echo "dtoverlay=vc4-kms-dsi-waveshare-panel,10_1_inch,dsi0"
echo "----------------------------------------"
echo ""
echo "🔧 Step 3: Create userconf.txt (optional)"
echo "Create userconf.txt with default pi user:"
echo "pi:\$6\$rBoByrWRKMY1EHFy\$ho.LISnfm83CLBWBE/yqJ7Mz7vTFQOBUFjk5zNDDKoUuWDwOqNJfzf6fXn6qOtY1j.lJJ8jKnZf5Qk5U5U5U5."
echo ""
echo "✅ After copying files:"
echo "   1. Safely eject SD card"
echo "   2. Insert into Pi and power on"
echo "   3. Setup runs automatically on first boot!"
