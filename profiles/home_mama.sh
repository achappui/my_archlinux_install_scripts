#!/usr/bin/env bash
set -euo pipefail

D=("/dev/sda")

PART_NAMES=(    "EFI"       "swap"      "root"      )
PART_SIZES=(    "+1G"       "+8G"       "0"         )
PART_TYPES=(    "ef00"      "8200"      "8300"      )
PART_DISK=(     "${D[0]}"   "${D[0]}"   "${D[0]}"   )

CPU_DRIVERS="cpu-intel"
GPU_DRIVERS="nvidia-max-volt.aur"

SWAY_MONITORS=("output HDMI-A-1 pos 0 0 res 1920x1200@60Hz" "output DVI-D-1 pos 1920 0 res 1680x1050@60Hz")
