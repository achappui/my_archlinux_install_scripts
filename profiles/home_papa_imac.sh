#!/bin/bash
set -euo pipefail

export D=("/dev/nvme0n1" "/dev/sda")

export PART_NAMES=(    "EFI"       "swap"      "root"      "home"      )
export PART_SIZES=(    "+1G"       "+1G"       "0"         "0"         )
export PART_TYPES=(    "ef00"      "8200"      "8300"      "8300"      )
export PART_DISK=(     "${D[0]}"   "${D[0]}"   "${D[0]}"   "${D[1]}"   )

export CPU_DRIVERS="cpu-intel"
export GPU_DRIVERS="intel"

export MY_PREFERED_MIRRORS_REGION="Switzerland,France,Germany,Austria,Italy"
export MY_CLOCK_REGION="Europe/Zurich"
export MY_LOCALE="en_US.UTF-8 UTF-8"
export MY_LANG="en_US.UTF-8"
export MY_KEYMAP="us"

export MY_IS_WIFI_SETUP="true"
export MY_IS_WIFI_ACTIVATED="true"

export SWAY_MONITORS=("output DP-3 pos 0 0 res 1920x1080@60Hz")
