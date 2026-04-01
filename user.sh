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

systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

xdg-user-dirs-update

cat <<EOF >> /home/${USER}/.bashrc

alias 'vi'='nvim'
alias 'sudo'='sudo '
alias 'ls --color=auto'
EOF

source /home/${USER}/.bashrc

sed -i "\|/home/${USER}/user.sh|d" /home/${USER}/.bash_profile

rm -- "$0"
