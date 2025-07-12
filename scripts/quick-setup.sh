#!/bin/bash

# Quick setup script - runs all configurations automatically
# Use this for completely automated setup

set -e

echo "🚀 Starting automated Raspberry Pi 5 setup..."

# Update system
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# Configure display
echo "🖥️  Configuring display..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
cat << 'EOF' | sudo tee -a /boot/firmware/config.txt

# Waveshare PI5-HMI-080C Display Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=ov5647
dtoverlay=vc4-kms-dsi-waveshare-panel,10_1_inch,dsi0
EOF

# Switch to X11
echo "🔄 Switching to X11..."
sudo raspi-config nonint do_wayland W1

# Install packages
echo "📋 Installing packages..."
sudo apt install -y xprintidle unclutter vim htop git curl wget screen tmux tree neofetch

# Setup auto-dimming
echo "💡 Setting up auto-dimming..."
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

# Setup cursor hiding
echo "🖱️  Setting up cursor hiding..."
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

echo "unclutter -idle 0 &" >> ~/.xsessionrc
echo 'echo -e "\033[?25l"' >> ~/.bashrc

echo "✅ Setup completed! Rebooting in 10 seconds..."
echo "Press Ctrl+C to cancel reboot"
sleep 10
sudo reboot
