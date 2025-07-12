#!/bin/bash

# Quick installer script - downloads and runs setup automatically

echo "🚀 Raspberry Pi 5 Quick Setup Installer"
echo "This will:"
echo "  - Update your system"
echo "  - Switch to X11"
echo "  - Setup auto-dimming"
echo "  - Configure autostart on boot"
echo ""

read -p "Continue? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Create setup directory
mkdir -p ~/pi-setup
cd ~/pi-setup

echo "📥 Creating setup script..."

# Create the main setup script
cat > simple-setup.sh << 'EOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Please run as pi user."
    exit 1
fi

log "Starting Raspberry Pi 5 setup..."

log "Running system update..."
sudo apt update && sudo apt full-upgrade -y

log "Switching to X11..."
sudo raspi-config nonint do_wayland W1

log "Installing xprintidle..."
sudo apt install -y xprintidle

log "Setting up auto-dimming..."
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'SCRIPT_EOF'
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
SCRIPT_EOF

sudo chmod +x /usr/local/bin/auto-dim.sh

sudo tee /etc/systemd/system/auto-dim.service > /dev/null << 'SERVICE_EOF'
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

sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service

log "✅ Setup completed! Dimming will autostart on every boot."
warn "Reboot required for changes to take effect."

read -p "Reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    log "Rebooting..."
    sudo reboot
else
    warn "Please reboot manually: sudo reboot"
fi
EOF

# Make executable
chmod +x simple-setup.sh

echo "✅ Setup script created!"
echo ""
echo "🚀 Running setup now..."
echo ""

# Run the setup
./simple-setup.sh
