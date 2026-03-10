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

source /home/${USER}/profile.sh

systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal

if [ "${PROFILE_NAME}" = "home_papa_imac" ]; then
    echo "ARPT" | sudo tee "/proc/acpi/wakeup"
    echo "GIGE" | sudo tee "/proc/acpi/wakeup"
    echo "XHC1" | sudo tee "/proc/acpi/wakeup"
fi

git clone https://aur.archlinux.org/yay.git /home/${USER}/yay
makepkg -si --dir /home/${USER}/yay
rm -rf /home/${USER}/yay

yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/home/${USER}/packages/desktops/sway.aur.list")

if echo ${GPU_DRIVERS} | grep -q ".aur"; then
    yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/home/${USER}/packages/drivers/${GPU_DRIVERS}.list")
fi

echo "alias 'vi'='nvim'" >> /home/${USER}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${USER}/.bashrc

rm /home/${USER}/profile.sh
rm -rf /home/${USER}/packages

source /home/${USER}/.bashrc
sed -i "\|/home/${USER}/user.sh|d" /home/${USER}/.bash_profile

rm -- "$0"
