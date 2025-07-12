#!/bin/bash

# Raspberry Pi 5 Setup Script for Waveshare PI5-HMI-080C
# This script automates the setup process for your Raspberry Pi

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as pi user."
        exit 1
    fi
}

# Update system
update_system() {
    log "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    log "System update completed"
}

# Configure display for Waveshare PI5-HMI-080C
configure_display() {
    log "Configuring Waveshare PI5-HMI-080C display..."
    
    # Backup original config
    sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
    
    # Add display configuration
    cat << 'EOF' | sudo tee -a /boot/firmware/config.txt

# Waveshare PI5-HMI-080C Display Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=ov5647
dtoverlay=vc4-kms-dsi-waveshare-panel,10_1_inch,dsi0
EOF
    
    log "Display configuration added to config.txt"
}

# Switch to X11 (required for auto-dimming)
switch_to_x11() {
    log "Switching to X11 display server..."
    
    # Enable X11 via raspi-config non-interactively
    sudo raspi-config nonint do_wayland W1
    
    log "Switched to X11. Reboot required to take effect."
}

# Install auto-dimming functionality
setup_auto_dimming() {
    log "Setting up auto-dimming functionality..."
    
    # Install required package
    sudo apt install -y xprintidle
    
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
    
    # Create systemd service
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
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable auto-dim.service
    
    log "Auto-dimming service configured and enabled"
}

# Hide mouse cursor
setup_cursor_hiding() {
    log "Setting up cursor hiding..."
    
    # Install unclutter
    sudo apt install -y unclutter
    
    # Add to autostart
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
    
    # Also add to .xsessionrc for compatibility
    echo "unclutter -idle 0 &" >> ~/.xsessionrc
    
    log "Cursor hiding configured"
}

# Hide text cursor in console
setup_console_cursor() {
    log "Configuring console cursor hiding..."
    
    # Add to .bashrc
    echo 'echo -e "\033[?25l"' >> ~/.bashrc
    
    log "Console cursor hiding configured"
}

# Install common useful packages
install_common_packages() {
    log "Installing common useful packages..."
    
    sudo apt install -y \
        vim \
        htop \
        git \
        curl \
        wget \
        screen \
        tmux \
        tree \
        neofetch
    
    log "Common packages installed"
}

# Main setup function
main() {
    log "Starting Raspberry Pi 5 setup for Waveshare PI5-HMI-080C..."
    
    check_root
    
    # Ask user what to install
    echo
    info "What would you like to set up? (y/n for each)"
    
    read -p "Update system packages? (y/n): " update_choice
    read -p "Configure Waveshare display? (y/n): " display_choice
    read -p "Switch to X11? (y/n): " x11_choice
    read -p "Setup auto-dimming? (y/n): " dimming_choice
    read -p "Hide mouse cursor? (y/n): " mouse_choice
    read -p "Hide console cursor? (y/n): " console_choice
    read -p "Install common packages? (y/n): " packages_choice
    
    echo
    
    # Execute chosen options
    [[ $update_choice =~ ^[Yy]$ ]] && update_system
    [[ $display_choice =~ ^[Yy]$ ]] && configure_display
    [[ $x11_choice =~ ^[Yy]$ ]] && switch_to_x11
    [[ $dimming_choice =~ ^[Yy]$ ]] && setup_auto_dimming
    [[ $mouse_choice =~ ^[Yy]$ ]] && setup_cursor_hiding
    [[ $console_choice =~ ^[Yy]$ ]] && setup_console_cursor
    [[ $packages_choice =~ ^[Yy]$ ]] && install_common_packages
    
    log "Setup completed successfully!"
    
    # Check if reboot is needed
    if [[ $display_choice =~ ^[Yy]$ ]] || [[ $x11_choice =~ ^[Yy]$ ]]; then
        warn "A reboot is required for display changes to take effect."
        read -p "Reboot now? (y/n): " reboot_choice
        if [[ $reboot_choice =~ ^[Yy]$ ]]; then
            log "Rebooting..."
            sudo reboot
        else
            warn "Please reboot manually when convenient."
        fi
    fi
}

# Run main function
main "$@"
