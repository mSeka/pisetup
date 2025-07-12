# 📋 Raspberry Pi 5 Setup Installation Guide

Complete step-by-step guide to install and run the automated setup scripts on your Raspberry Pi 5.

## 🎯 What This Will Do

- Update your system (`sudo apt update && sudo apt full-upgrade`)
- Switch to X11 display server
- Setup automatic display dimming after 30 seconds of inactivity
- Configure dimming to start automatically on every boot

## 📋 Prerequisites

- Raspberry Pi 5 with Raspberry Pi OS installed
- SSH access or direct terminal access to your Pi
- Internet connection on your Pi

---

## 🚀 Method 1: Copy-Paste Installation (Recommended)

### Step 1: Connect to Your Pi

**Option A: Direct access**
- Connect keyboard/mouse to your Pi
- Open Terminal

**Option B: SSH access**
\`\`\`bash
ssh pi@YOUR_PI_IP_ADDRESS
\`\`\`

### Step 2: Create Setup Directory

\`\`\`bash
# Create directory for scripts
mkdir ~/pi-setup
cd ~/pi-setup
\`\`\`

### Step 3: Create the Setup Script

Copy and paste this command to create the main setup script:

\`\`\`bash
cat > simple-setup.sh << 'EOF'
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
sudo tee /usr/local/bin/auto-dim.sh > /dev/null << 'SCRIPT_EOF'
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
SCRIPT_EOF

# Make script executable
sudo chmod +x /usr/local/bin/auto-dim.sh

# Create systemd service that AUTOMATICALLY STARTS ON BOOT
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

# Reload systemd and enable service for AUTOSTART
sudo systemctl daemon-reload
sudo systemctl enable auto-dim.service

log "Display dimming service configured and enabled for autostart"
log "✅ Service will AUTOMATICALLY START on every boot"

log "Setup completed successfully!"
warn "A reboot is required for changes to take effect."

read -p "Reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    log "Rebooting..."
    sudo reboot
else
    warn "Please reboot manually: sudo reboot"
fi
EOF
\`\`\`

### Step 4: Create Check Script (Optional)

\`\`\`bash
cat > check-dimming.sh << 'EOF'
#!/bin/bash

echo "🔍 Checking auto-dimming service status..."

# Check if service is enabled (will start on boot)
if sudo systemctl is-enabled --quiet auto-dim.service; then
    echo "✅ Auto-dimming service is ENABLED (will start on boot)"
else
    echo "❌ Auto-dimming service is NOT enabled for autostart"
fi

# Check if service is currently running
if sudo systemctl is-active --quiet auto-dim.service; then
    echo "✅ Auto-dimming service is currently RUNNING"
else
    echo "❌ Auto-dimming service is NOT running"
fi

# Show detailed status
echo ""
echo "📊 Detailed service status:"
sudo systemctl status auto-dim.service --no-pager -l

# Check X11 session
echo ""
echo "🖥️  Display session type: $XDG_SESSION_TYPE"
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    echo "✅ X11 is active (required for dimming)"
else
    echo "❌ X11 is not active. Dimming requires X11."
fi
EOF
\`\`\`

### Step 5: Make Scripts Executable

\`\`\`bash
chmod +x simple-setup.sh
chmod +x check-dimming.sh
\`\`\`

### Step 6: Run the Setup

\`\`\`bash
./simple-setup.sh
\`\`\`

**What happens next:**
1. Script will update your system (this takes a few minutes)
2. Switch to X11
3. Install xprintidle
4. Setup dimming service
5. Ask if you want to reboot

**Choose 'y' to reboot when prompted.**

---

## 🚀 Method 2: One-Command Installation

If you want everything automated without prompts:

\`\`\`bash
# Create and run automated setup
mkdir ~/pi-setup && cd ~/pi-setup

curl -s << 'EOF' | bash
#!/bin/bash
echo "🚀 Starting automated Pi setup..."
sudo apt update && sudo apt full-upgrade -y
sudo raspi-config nonint do_wayland W1
sudo apt install -y xprintidle

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
echo "✅ Setup complete! Rebooting in 5 seconds..."
sleep 5
sudo reboot
EOF
\`\`\`

---

## ✅ After Installation

### Step 1: Wait for Reboot
Your Pi will reboot automatically. Wait for it to come back online.

### Step 2: Verify Installation
\`\`\`bash
cd ~/pi-setup
./check-dimming.sh
\`\`\`

You should see:
- ✅ Auto-dimming service is ENABLED
- ✅ Auto-dimming service is currently RUNNING
- ✅ X11 is active

### Step 3: Test Dimming
1. Don't touch your Pi for 30 seconds
2. Screen should dim automatically
3. Touch screen or move mouse - it should brighten again

---

## 🔧 Troubleshooting

### Problem: Dimming not working after reboot

**Solution:**
\`\`\`bash
# Check service status
sudo systemctl status auto-dim.service

# Restart service
sudo systemctl restart auto-dim.service

# Check if X11 is active
echo $XDG_SESSION_TYPE
\`\`\`

### Problem: Service not starting automatically

**Solution:**
\`\`\`bash
# Re-enable autostart
sudo systemctl enable auto-dim.service
sudo systemctl start auto-dim.service
\`\`\`

### Problem: Wrong display path

**Solution:**
\`\`\`bash
# Find correct backlight path
ls /sys/class/backlight/

# Edit the script with correct path
sudo nano /usr/local/bin/auto-dim.sh
\`\`\`

---

## 🎛️ Customization

### Change Dimming Timeout
\`\`\`bash
# Edit the script
sudo nano /usr/local/bin/auto-dim.sh

# Change IDLE_TIME_MS:
# 30000 = 30 seconds (default)
# 60000 = 1 minute  
# 120000 = 2 minutes

# Restart service after changes
sudo systemctl restart auto-dim.service
\`\`\`

### Change Brightness Levels
\`\`\`bash
# Edit brightness values in the script
sudo nano /usr/local/bin/auto-dim.sh

# DIM_BRIGHTNESS=51 (dimmed level)
# NORMAL_BRIGHTNESS=255 (full brightness)

# Restart service after changes
sudo systemctl restart auto-dim.service
\`\`\`

---

## 🗑️ Uninstall

To remove the dimming setup:
\`\`\`bash
# Stop and disable service
sudo systemctl stop auto-dim.service
sudo systemctl disable auto-dim.service

# Remove files
sudo rm /etc/systemd/system/auto-dim.service
sudo rm /usr/local/bin/auto-dim.sh

# Reload systemd
sudo systemctl daemon-reload
\`\`\`

---

## 📞 Support

If you have issues:
1. Run `./check-dimming.sh` to diagnose
2. Check logs: `sudo journalctl -u auto-dim.service`
3. Verify X11: `echo $XDG_SESSION_TYPE`

The setup should work automatically after installation and reboot! 🎉
