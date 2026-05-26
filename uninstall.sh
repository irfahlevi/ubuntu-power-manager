#!/bin/bash
set -e

echo "=== Ubuntu Power Manager Uninstaller ==="

echo "[1/4] Stopping service..."
sudo systemctl stop power-profile-freq-cap.service 2>/dev/null || true

echo "[2/4] Disabling service..."
sudo systemctl disable power-profile-freq-cap.service 2>/dev/null || true

echo "[3/4] Removing files..."
sudo rm -f /usr/local/bin/power-profile-freq-cap.sh
sudo rm -f /usr/local/bin/powerprofilesctl
sudo rm -f /etc/systemd/system/power-profile-freq-cap.service
sudo rm -f /etc/udev/rules.d/50-nvidia-power-save.rules

echo "[4/4] Reloading..."
sudo udevadm control --reload-rules
sudo systemctl daemon-reload

echo ""
echo "=== Uninstallation complete! ==="
echo "Reboot to restore default power behavior."
