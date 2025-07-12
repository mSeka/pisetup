#!/bin/bash

# Service file to run the firstboot setup
# This gets created automatically by the setup process

cat > /etc/systemd/system/firstboot-setup.service << 'EOF'
[Unit]
Description=First Boot Setup for Raspberry Pi 5
After=multi-user.target
Before=getty@tty1.service

[Service]
Type=oneshot
ExecStart=/boot/firmware/firstboot-setup.sh
StandardOutput=journal+console
StandardError=journal+console
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable firstboot-setup.service
