#!/bin/bash

# Script to check if auto-dimming is working properly

echo "🔍 Checking auto-dimming service status..."

# Check if service exists
if ! sudo systemctl list-unit-files | grep -q auto-dim.service; then
    echo "❌ Auto-dimming service not found"
    exit 1
fi

# Check if service is enabled (will start on boot)
if sudo systemctl is-enabled --quiet auto-dim.service; then
    echo "✅ Auto-dimming service is ENABLED (will start on boot)"
else
    echo "❌ Auto-dimming service is NOT enabled for autostart"
    echo "Run: sudo systemctl enable auto-dim.service"
fi

# Check if service is currently running
if sudo systemctl is-active --quiet auto-dim.service; then
    echo "✅ Auto-dimming service is currently RUNNING"
else
    echo "❌ Auto-dimming service is NOT running"
    echo "Run: sudo systemctl start auto-dim.service"
fi

# Show detailed status
echo ""
echo "📊 Detailed service status:"
sudo systemctl status auto-dim.service --no-pager

# Check X11 session
echo ""
echo "🖥️  Display session type:"
echo "Current session: $XDG_SESSION_TYPE"
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    echo "✅ X11 is active (required for dimming)"
else
    echo "❌ X11 is not active. Dimming requires X11."
    echo "Run: sudo raspi-config nonint do_wayland W1"
fi

# Check if xprintidle works
echo ""
echo "⏱️  Testing idle detection:"
if command -v xprintidle &> /dev/null; then
    idle_time=$(xprintidle 2>/dev/null || echo "error")
    if [ "$idle_time" != "error" ]; then
        echo "✅ Idle detection working (current idle: ${idle_time}ms)"
    else
        echo "❌ Idle detection not working (may need X11 session)"
    fi
else
    echo "❌ xprintidle not installed"
fi

# Check backlight path
echo ""
echo "💡 Checking backlight control:"
BACKLIGHT_PATH="/sys/class/backlight/10-0045/brightness"
if [ -f "$BACKLIGHT_PATH" ]; then
    current_brightness=$(cat "$BACKLIGHT_PATH")
    echo "✅ Backlight control available (current: $current_brightness)"
else
    echo "❌ Backlight path not found: $BACKLIGHT_PATH"
    echo "Available backlights:"
    ls /sys/class/backlight/ 2>/dev/null || echo "None found"
fi
