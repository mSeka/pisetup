# 🚀 One-Command Raspberry Pi 5 Setup

Super simple setup for Raspberry Pi 5 with auto-dimming display.

## ⚡ One Command Installation

\`\`\`bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/pi-setup/main/install.sh | bash
\`\`\`

That's it! 🎉

## 📋 What It Does

- ✅ Updates system packages
- ✅ Switches to X11 display server  
- ✅ Sets up auto-dimming after 30 seconds
- ✅ Configures autostart on every boot
- ✅ Asks to reboot when done

## ⏱️ Timeline

- **2-8 minutes**: System updates
- **1 minute**: X11 + dimming setup
- **Total**: ~5-10 minutes

## 🔧 After Installation

**Test dimming:**
- Don't touch Pi for 30 seconds
- Screen dims automatically
- Touch screen → brightens again

**Check status:**
\`\`\`bash
sudo systemctl status auto-dim.service
\`\`\`

## 🎛️ Customization

To change dimming timeout:
\`\`\`bash
sudo nano /usr/local/bin/auto-dim.sh
# Change IDLE_TIME_MS (30000 = 30 seconds)
sudo systemctl restart auto-dim.service
\`\`\`

## 🗑️ Uninstall

\`\`\`bash
sudo systemctl stop auto-dim.service
sudo systemctl disable auto-dim.service
sudo rm /etc/systemd/system/auto-dim.service
sudo rm /usr/local/bin/auto-dim.sh
\`\`\`

Perfect for quick Pi setup! 🚀
