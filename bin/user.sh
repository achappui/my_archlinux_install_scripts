#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Arch Linux Automated Installer
# --------------------------------------------------
#
# Stage 1: startup.sh
#   - disk partition
#   - pacstrap
#
# Stage 2: chroot.sh
#   - system configuration
#   - packages install
#
# Stage 3: user.sh
#   - user environment
#   - AUR packages
#
# Supported machines:
#   - home_papa
#   - home_maman
#   - home_papa_imac
#
# Author: <me>
# ==================================================

source /home/${MY_USER}/profile.sh

systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal

git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
makepkg -si --dir /home/${USER}/yay
rm -r /home/${MY_USER}/yay

yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/home/${MY_USER}/packages/desktops/sway.aur.list")

if grep -q ".aur" ${GPU_DRIVERS}; then
    yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/home/${MY_USER}/packages/drivers/${GPU_DRIVERS}.list")
fi

echo "alias 'vi'='nvim'" >> /home/${USER}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${USER}/.bashrc

rm /home/${MY_USER}/profile.sh
rm -r /home/${MY_USER}/packages

source /home/${USER}/.bashrc
sed -i "\|/home/${USER}/user.sh|d" /home/${USER}/.bash_profile

rm -- "$0"
