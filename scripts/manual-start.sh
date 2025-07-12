#!/bin/bash

# Manual script to start dimming if it's not working automatically

echo "🚀 Manually starting auto-dimming..."

# Check if we're in X11
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    echo "❌ Not in X11 session. Dimming requires X11."
    echo "Switch to X11 with: sudo raspi-config nonint do_wayland W1"
    exit 1
fi

# Start the service
sudo systemctl start auto-dim.service

# Check if it started
if sudo systemctl is-active --quiet auto-dim.service; then
    echo "✅ Auto-dimming service started successfully"
    echo "✅ It will now start automatically on future boots"
else
    echo "❌ Failed to start service"
    echo "Check logs with: sudo journalctl -u auto-dim.service"
fi
