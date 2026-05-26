#!/bin/bash

CAP_FREQ=1400000
BALANCED_FREQ=2500000
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
GPU_DPM="/sys/class/drm/card1/device/power_dpm_force_performance_level"
GPU_PPM="/sys/class/drm/card1/device/pp_power_profile_mode"
NVIDIA_GPU="/sys/bus/pci/devices/0000:01:00.0"
NVIDIA_AUDIO="/sys/bus/pci/devices/0000:01:00.1"
ASPM="/sys/module/pcie_aspm/parameters/policy"

set_freq() {
    local freq=$1
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo "$freq" > "$cpu" 2>/dev/null
    done
}

set_boost() {
    echo "$1" > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
}

set_gpu() {
    local level=$1
    local mode=$2
    if [ -f "$GPU_DPM" ]; then
        echo "$level" > "$GPU_DPM" 2>/dev/null
    fi
    if [ -f "$GPU_PPM" ] && [ -n "$mode" ]; then
        echo "$mode" > "$GPU_PPM" 2>/dev/null
    fi
}

set_nvidia() {
    local state=$1
    if [ "$state" = "off" ]; then
        if [ -d "$NVIDIA_GPU" ]; then
            echo auto > "$NVIDIA_GPU/power/control" 2>/dev/null
        fi
        if [ -d "$NVIDIA_AUDIO" ]; then
            echo auto > "$NVIDIA_AUDIO/power/control" 2>/dev/null
        fi
    else
        if [ -d "$NVIDIA_GPU" ]; then
            echo on > "$NVIDIA_GPU/power/control" 2>/dev/null
        fi
        if [ -d "$NVIDIA_AUDIO" ]; then
            echo on > "$NVIDIA_AUDIO/power/control" 2>/dev/null
        fi
    fi
}

set_aspm() {
    local mode=$1
    if [ -f "$ASPM" ]; then
        echo "$mode" > "$ASPM" 2>/dev/null
    fi
}

apply_profile() {
    local profile=$1
    if [ "$profile" = "power-saver" ]; then
        set_nvidia off
        set_aspm "powersupersave"
        set_boost 0
        set_freq "$CAP_FREQ"
        set_gpu "low" "3"
        echo "power-saver: 1.4GHz | boost off | GPU low/video | NVIDIA off | ASPM powersupersave"
    elif [ "$profile" = "balanced" ]; then
        set_nvidia off
        set_aspm "powersupersave"
        set_boost 0
        set_freq "$BALANCED_FREQ"
        set_gpu "low" ""
        echo "balanced: 2.5GHz | boost off | GPU low | NVIDIA off | ASPM powersupersave"
    else
        set_nvidia on
        set_aspm "default"
        set_boost 1
        set_freq "$MAX_FREQ"
        set_gpu "auto" ""
        echo "performance: 4.47GHz | boost on | GPU auto | NVIDIA on | ASPM default"
    fi
}

sleep 8
apply_profile "$(powerprofilesctl get 2>/dev/null)"

LAST_PROFILE=""

while true; do
    PROFILE=$(powerprofilesctl get 2>/dev/null)
    if [ "$PROFILE" != "$LAST_PROFILE" ] && [ -n "$PROFILE" ]; then
        sleep 2
        PROFILE=$(powerprofilesctl get 2>/dev/null)
        if [ "$PROFILE" != "$LAST_PROFILE" ]; then
            LAST_PROFILE="$PROFILE"
            apply_profile "$PROFILE"
        fi
    fi
    sleep 5
done
