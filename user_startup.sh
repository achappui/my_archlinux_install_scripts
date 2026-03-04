#!/bin/bash
set -e

systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber

git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
makepkg -si --dir /home/${MY_USER}/yay
rm -rf /home/${MY_USER}/yay

yay -Syu --noconfirm --needed ${MY_YAY_PACKAGES}

if [ ${MY_IS_IMAC} = "true" ]; then
    pacman -Syu --noconfirm --needed mesa libva intel-ucode
else
	yay -Syu --noconfirm --needed linux-headers nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils

echo "#!/bin/sh
/usr/lib/xdg-desktop-portal &
/usr/lib/xdg-desktop-portal-gtk &

sleep 2
feh --bg-fill /home/${MY_USER}/Pictures/wall/gruv.png &
 " > /home/${MY_USER}/.xinitrc

echo "alias 'vi'='nvim'" >> /home/${MY_USER}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${MY_USER}/.bashrc

source /home/${MY_USER}/.bashrc
sed -i "\|/home/${MY_USER}/user_startup.sh|d" /home/${MY_USER}/.bash_profile

rm -- "$0"
