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


systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr

git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
makepkg -si --dir /home/${MY_USER}/yay
rm -rf /home/${MY_USER}/yay

yay -Syu --noconfirm --needed ${MY_YAY_PACKAGES}

if [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    sudo pacman -Syu --noconfirm --needed mesa libva intel-ucode
fi

if [ ${MY_WHICH_COMPUTER} = "home_papa" ]; then
    echo "output DP-4 pos 0 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
    echo "output HDMI-A-0 pos 1920 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
elif [ ${MY_WHICH_COMPUTER} = "home_maman" ]; then
    echo "output HDMI-A-1 pos 0 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
    echo "output DVI-D-1 pos 1920 0 res 1680x1050@60Hz" >> /home/${MY_USER}/.config/sway/config
elif [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    echo "output DP-3 pos 0 0 res 1920x1080@60Hz" >> /home/${MY_USER}/.config/sway/config
fi

echo "alias 'vi'='nvim'" >> /home/${MY_USER}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${MY_USER}/.bashrc

source /home/${MY_USER}/.bashrc
sed -i "\|/home/${MY_USER}/user_startup.sh|d" /home/${MY_USER}/.bash_profile

rm -- "$0"
