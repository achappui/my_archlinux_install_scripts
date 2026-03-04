#!/bin/bash
set -e

systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr

git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
makepkg -si --dir /home/${MY_USER}/yay
rm -rf /home/${MY_USER}/yay

yay -Syu --noconfirm --needed ${MY_YAY_PACKAGES}

if [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    pacman -Syu --noconfirm --needed mesa libva intel-ucode
else
	yay -Syu --noconfirm --needed linux-headers nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils

#Work only if sway is up
# exec_always --no-startup-id swaybg -i /home/${MY_USER}/Pictures/wall/gruv.png -m fill

echo "alias 'vi'='nvim'" >> /home/${MY_USER}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${MY_USER}/.bashrc

source /home/${MY_USER}/.bashrc
sed -i "\|/home/${MY_USER}/user_startup.sh|d" /home/${MY_USER}/.bash_profile

rm -- "$0"
