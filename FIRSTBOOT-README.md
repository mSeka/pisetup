# 🚀 Automatic First Boot Setup

This setup allows your Raspberry Pi 5 to automatically configure itself on the very first boot, without any manual intervention.

## 🎯 What Happens on First Boot

1. ✅ System updates (`apt update && apt full-upgrade`)
2. ✅ Switches to X11 display server
3. ✅ Installs xprintidle for dimming
4. ✅ Sets up auto-dimming service
5. ✅ Configures autostart on every boot
6. ✅ Automatically reboots when complete

## 📋 Setup Methods

### Method 1: Automated SD Card Preparation

\`\`\`bash
# Run this on your computer with SD card inserted
./prepare-sd-card.sh
\`\`\`

### Method 2: Manual File Copy

1. **Flash Raspberry Pi OS** using Raspberry Pi Imager
2. **Re-insert SD card** (don't eject after flashing)
3. **Copy firstboot-setup.sh** to the boot partition
4. **Add display config** to config.txt
5. **Eject and boot**

## 📁 Files Added to Boot Partition

- \`firstboot-setup.sh\` - Main setup script
- \`config.txt\` - Display configuration added
- \`userconf.txt\` - Default user setup (optional)

## ⏱️ Timeline

- **0-2 minutes**: Pi boots, starts setup
- **2-10 minutes**: System updates
- **10-12 minutes**: Package installation
- **12-15 minutes**: Service setup, reboot
- **15+ minutes**: Ready to use with auto-dimming!

## 📊 Monitor Progress

\`\`\`bash
# SSH to pi and watch the log
tail -f /boot/firmware/firstboot-setup.log
\`\`\`

## 🔧 Customization

Edit \`firstboot-setup.sh\` before copying to change:
- Dimming timeout (IDLE_TIME_MS)
- Brightness levels
- Additional packages

## ✅ Verification

After first boot completes:
\`\`\`bash
# Check if dimming service is running
sudo systemctl status auto-dim.service

# Test dimming (wait 30 seconds)
# Screen should dim automatically
\`\`\`

## 🚨 Troubleshooting

**Setup didn't run?**
- Check if firstboot-setup.sh exists in /boot/firmware/
- Check log: \`cat /boot/firmware/firstboot-setup.log\`

**Dimming not working?**
- Verify X11: \`echo $XDG_SESSION_TYPE\`
- Check service: \`sudo systemctl status auto-dim.service\`

Perfect for bulk Pi deployments! 🎉
