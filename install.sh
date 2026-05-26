#!/bin/bash
set -e

echo "=== Ubuntu Power Manager Installer ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/5] Installing power-profile-freq-cap.sh..."
sudo cp "$SCRIPT_DIR/scripts/power-profile-freq-cap.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/power-profile-freq-cap.sh

echo "[2/5] Installing systemd service..."
sudo cp "$SCRIPT_DIR/scripts/power-profile-freq-cap.service" /etc/systemd/system/

echo "[3/5] Installing NVIDIA power save udev rule..."
sudo cp "$SCRIPT_DIR/udev/50-nvidia-power-save.rules" /etc/udev/rules.d/

echo "[4/5] Installing powerprofilesctl wrapper..."
sudo cp "$SCRIPT_DIR/scripts/powerprofilesctl" /usr/local/bin/
sudo chmod +x /usr/local/bin/powerprofilesctl

echo "[5/5] Enabling service..."
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl daemon-reload
sudo systemctl enable power-profile-freq-cap.service

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage:"
echo "  Taskbar switching: Works automatically (GNOME power profiles menu)"
echo "  CLI switching:     sudo power-set <power-saver|balanced|performance>"
echo ""
echo "Current profile: $(powerprofilesctl get)"
echo ""
echo "Reboot to apply all changes, or run:"
echo "  sudo systemctl start power-profile-freq-cap.service"
