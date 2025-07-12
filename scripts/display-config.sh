#!/bin/bash

# Separate script to add display configuration to config.txt
# Run this if you need to configure the Waveshare display

echo "🖥️  Adding Waveshare PI5-HMI-080C display configuration..."

# Backup original config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# Add display configuration
cat << 'EOF' | sudo tee -a /boot/firmware/config.txt

# Waveshare PI5-HMI-080C Display Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=ov5647
dtoverlay=vc4-kms-dsi-waveshare-panel,10_1_inch,dsi0
EOF

echo "✅ Display configuration added!"
echo "⚠️  Reboot required for changes to take effect"
