#!/bin/bash

# Installation script - downloads and sets up all scripts
# Run this first on a fresh Pi

echo "📥 Installing Raspberry Pi setup scripts..."

# Create scripts directory
mkdir -p ~/pi-setup-scripts
cd ~/pi-setup-scripts

# Download scripts (you'll need to host these or copy them manually)
echo "📋 Setting up scripts..."

# Make all scripts executable
chmod +x *.sh

echo "✅ Installation complete!"
echo ""
echo "Available scripts:"
echo "  ./setup-pi.sh      - Interactive setup with options"
echo "  ./quick-setup.sh    - Automated full setup"
echo "  ./config-only.sh    - Display configuration only"
echo ""
echo "Run './setup-pi.sh' to start interactive setup"
