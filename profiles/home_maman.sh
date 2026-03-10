#!/usr/bin/env bash
set -euo pipefail

export PROFILE_NAME="home_maman"

export D=("/dev/sda")

export PART_NAMES=(    "EFI"       "swap"      "root"      )
export PART_SIZES=(    "+1G"       "+8G"       "0"         )
export PART_TYPES=(    "ef00"      "8200"      "8300"      )
export PART_DISK=(     "${D[0]}"   "${D[0]}"   "${D[0]}"   )

export CPU_DRIVERS="cpu-intel"
export GPU_DRIVERS="nvidia-max-volt.aur"

export MY_PREFERED_MIRRORS_REGION="Switzerland,France,Germany,Austria,Italy"
export MY_CLOCK_REGION="Europe/Zurich"
export MY_LOCALE="en_US.UTF-8 UTF-8"
export MY_LANG="en_US.UTF-8"
export MY_KEYMAP="us"

export MY_IS_WIFI_SETUP="false"

export SWAY_MONITORS=("output HDMI-A-1 pos 0 0 res 1920x1200@60Hz" "output DVI-D-1 pos 1920 0 res 1680x1050@60Hz")
