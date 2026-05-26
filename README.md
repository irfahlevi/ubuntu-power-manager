# Ubuntu Power Manager

Custom power management for Ubuntu on AMD Ryzen + NVIDIA hybrid GPU laptops. Optimized for **Lenovo Legion 7 16ACHg6 (82N6) with Ryzen 7 5800H + RTX 3060 Mobile / AMD Radeon Vega**.

Reduces power draw from ~34W to ~14W (~58% reduction), extending battery life from ~1.7 hrs to ~4.5 hrs.

## Profile Config

| Setting | Power Saver | Balanced | Performance |
|---------|------------|----------|-------------|
| CPU Max Freq | 1.4 GHz | 2.5 GHz | 4.47 GHz |
| Turbo Boost | Off | Off | On |
| AMD GPU DPM | Low | Low | Auto |
| AMD GPU Mode | Video | Default | Default |
| NVIDIA GPU | Suspended (D3cold) | Suspended (D3cold) | Active |
| PCIe ASPM | powersupersave | powersupersave | default |
| Est. Power Draw | ~11-13W | ~14-16W | ~30-34W |
| Est. Battery Life (67Wh) | **5-6 hrs** | **4-4.5 hrs** | **2-2.5 hrs** |

## Requirements

- Ubuntu 22.04+ with GNOME
- AMD Ryzen CPU with `amd-pstate-epp` driver
- AMD integrated GPU (iGPU)
- NVIDIA discrete GPU (dGPU) — optional, will be suspended if present
- `power-profiles-daemon` (installed by default on Ubuntu GNOME)
- `powerprofilesctl` command available

## Quick Install

```bash
git clone https://github.com/irfahlevi/ubuntu-power-manager.git
cd ubuntu-power-manager
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

Then reboot:

```bash
sudo reboot
```

## Usage

### Taskbar Switching (Recommended)

Switch profiles from the GNOME top bar power menu. The background service detects changes and applies all custom settings automatically within ~10 seconds.

### CLI Switching

```bash
sudo power-set power-saver     # Max battery life
sudo power-set balanced        # Daily use
sudo power-set performance     # Full power
```

### Check Current Status

```bash
powerprofilesctl get                                      # Current profile
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq # CPU max freq
cat /sys/devices/system/cpu/cpufreq/boost                 # Turbo boost
cat /sys/class/drm/card1/device/power_dpm_force_performance_level  # AMD GPU
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status          # NVIDIA GPU
cat /sys/module/pcie_aspm/parameters/policy                         # PCIe ASPM
```

## How It Works

### Background Service (`power-profile-freq-cap.service`)

Runs as a systemd service that:

1. Waits 8 seconds on boot for `power-profiles-daemon` to initialize
2. Applies custom settings based on the current profile
3. Polls `powerprofilesctl get` every 5 seconds to detect profile changes
4. When a change is detected, waits 2 seconds for the daemon to finish, then applies custom settings

### NVIDIA GPU Suspend

The udev rule (`50-nvidia-power-save.rules`) forces all NVIDIA PCIe devices into runtime suspend (D3cold) via `power/control = auto`. This saves ~5-10W since the dGPU has no driver loaded.

### powerprofilesctl Wrapper

The `/usr/local/bin/powerprofilesctl` wrapper intercepts CLI calls and ensures all CPUs are online before calling the real `/usr/bin/powerprofilesctl`. This prevents "device busy" errors when SMT cores are offlined.

## Customize

Edit `/usr/local/bin/power-profile-freq-cap.sh` to adjust:

```bash
CAP_FREQ=1400000        # Power-saver max freq in kHz
BALANCED_FREQ=2500000   # Balanced max freq in kHz
# MAX_FREQ is auto-detected from hardware
```

After editing:

```bash
sudo systemctl restart power-profile-freq-cap.service
```

## Troubleshooting

### Profile won't switch from taskbar

The service may need a restart:

```bash
sudo systemctl restart power-profile-freq-cap.service
```

### "Device or resource busy" error

This happens when SMT toggling conflicts with `powerprofilesctl`. The current version avoids this by keeping all CPU threads online. If you experience this, reboot to clear the state.

### Check service logs

```bash
sudo systemctl status power-profile-freq-cap.service
```

## Uninstall

```bash
sudo ./uninstall.sh
sudo reboot
```

## Hardware Tested On

- **Laptop**: Lenovo Legion 7 16ACHg6 (82N6)
- **CPU**: AMD Ryzen 7 5800H (8C/16T)
- **iGPU**: AMD Radeon Vega (Cezanne)
- **dGPU**: NVIDIA RTX 3060 Mobile Max-Q
- **OS**: Ubuntu 24.04+ with GNOME 46, kernel 6.18+

## License

MIT
