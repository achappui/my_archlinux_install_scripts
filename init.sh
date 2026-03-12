#!/usr/bin/env bash
set -euo pipefail

pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm --needed git

git clone "https://github.com/achappui/my_archlinux_install_scripts"

/bin/bash my_archlinux_install_scripts/bin/startup.sh
