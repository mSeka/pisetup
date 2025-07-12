#!/bin/bash

# Ultra-simple version - no prompts, just runs everything
echo "🚀 Auto-installing Pi setup..."

sudo apt update && sudo apt full-upgrade -y
sudo raspi-config nonint do_wayland W1
sudo apt install -y xprintidle

sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
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
EOF

sudo chmod +x /usr/local/bin/auto-dim.sh

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

sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service

echo "✅ Setup complete! Rebooting in 5 seconds..."
sleep 5
sudo reboot
