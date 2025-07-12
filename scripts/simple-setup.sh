#!/bin/bash

# Simple Raspberry Pi 5 Setup Script
# Only does: system update, X11 switch, and display dimming setup

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Please run as pi user."
    exit 1
fi

log "Starting simple Raspberry Pi 5 setup..."

# 1. System update
log "Running system update..."
sudo apt update
sudo apt full-upgrade -y
log "System update completed"

# 2. Switch to X11
log "Switching to X11 display server..."
sudo raspi-config nonint do_wayland W1
log "Switched to X11"

# 3. Install only xprintidle (needed for dimming)
log "Installing xprintidle for display dimming..."
sudo apt install -y xprintidle

# 4. Setup auto-dimming
log "Setting up display dimming..."

# Create auto-dim script
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'EOF'
#!/bin/bash

# Auto-dimming configuration
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

# Make script executable
sudo chmod +x /usr/local/bin/auto-dim.sh

# Create systemd service that AUTOMATICALLY STARTS ON BOOT
sudo tee /etc/systemd/system/auto-dim.service > /dev/null << 'EOF'
[Unit]
Description=Auto Dim Display After Inactivity
After=multi-user.target
Wants=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/auto-dim.sh
Restart=always
RestartSec=5
User=pi
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service for AUTOSTART
sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service
sudo systemctl start auto-dim.service

log "Display dimming service configured, enabled, and started"
log "✅ Service will AUTOMATICALLY START on every boot"

# Verify service is running
if sudo systemctl is-active --quiet auto-dim.service; then
    log "✅ Auto-dimming service is currently running"
else
    warn "⚠️  Service may not be running yet (normal after X11 switch)"
fi

log "Setup completed successfully!"
warn "A reboot is required for X11 changes to take effect."
warn "After reboot, the dimming service will start automatically."

read -p "Reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]] && [[ $reboot_choice =~ ^[Yy]$ ]]; then
    log "Rebooting..."
    sudo reboot
else
    warn "Please reboot manually when convenient."
    warn "After reboot, check service status with: sudo systemctl status auto-dim.service"
fi
