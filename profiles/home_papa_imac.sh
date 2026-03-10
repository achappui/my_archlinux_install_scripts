#!/bin/bash
set -euo pipefail

D=("/dev/nvme0n1" "/dev/sda")

PART_NAMES=(    "EFI"       "swap"      "root"      "home"      )
PART_SIZES=(    "+1G"       "+1G"       "0"         "0"         )
PART_TYPES=(    "ef00"      "8200"      "8300"      "8300"      )
PART_DISK=(     "${D[0]}"   "${D[0]}"   "${D[0]}"   "${D[1]}"   )

CPU_DRIVERS="cpu-intel"
GPU_DRIVERS="intel"

SWAY_MONITORS=("output DP-3 pos 0 0 res 1920x1080@60Hz")
