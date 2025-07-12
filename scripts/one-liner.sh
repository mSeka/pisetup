#!/bin/bash

# Ultra-simple one-liner version
# Does everything in sequence without prompts

echo "🚀 Starting automated Pi setup..."

# Update system
sudo apt update && sudo apt full-upgrade -y

# Switch to X11
sudo raspi-config nonint do_wayland W1

# Install xprintidle
sudo apt install -y xprintidle

# Create dimming script
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
#!/bin/bash
IDLE_TIME_MS=30000
DIM_BRIGHTNESS=51
NORMAL_BRIGHTNESS=255
BACKLIGHT_PATH="/sys/class/backlight/10-0045/brightness"
already_dimmed=0
while true; do
    idle=$(xprintidle)
    if [ "$idle" -ge "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 0 ]; then
        echo "$DIM_BRIGHTNESS" > "$BACKLIGHT_PATH"
        already_dimmed=1
    elif [ "$idle" -lt "$IDLE_TIME_MS" ] && [ "$already_dimmed" -eq 1 ]; then
        echo "$NORMAL_BRIGHTNESS" > "$BACKLIGHT_PATH"
        already_dimmed=0
    fi
    sleep 1
done
EOF

sudo chmod +x /usr/local/bin/auto-dim.sh

# Create and enable service
sudo tee /etc/systemd/system/auto-dim.service > /dev/null << 'EOF'
[Unit]
Description=Auto Dim Display After Inactivity
After=multi-user.target
[Service]
ExecStart=/usr/local/bin/auto-dim.sh
Restart=always
User=pi
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service

echo "✅ Setup complete! Rebooting in 5 seconds..."
sleep 5
sudo reboot
