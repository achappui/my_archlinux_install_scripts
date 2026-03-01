#!/bin/bash
set -e

systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber

git clone https://aur.archlinux.org/yay.git /home/${MY_USER_NAME}/yay
makepkg -si --dir /home/${MY_USER_NAME}/yay
rm -rf /home/${MY_USER_NAME}/yay

yay -Syu --noconfirm --needed linux-headers pinta brave-bin google-chrome nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils

echo "#!/bin/sh
/usr/lib/xdg-desktop-portal & #REMPLACER PAR DBUS
/usr/lib/xdg-desktop-portal-gtk &
VBoxClient-all &
xrandr --output Virtual-1 --mode 1920x1080
xrandr --output Virtual-2 --mode 1920x1080
sleep 2
xrdb merge pathToXresourcesFile
xrdb merge /home/${MY_USER_NAME}/.Xresources 
xbacklight -set 10 &
feh --bg-fill /home/${MY_USER_NAME}/Pictures/wall/gruv.png &
xset r rate 180 50 & " > /home/${MY_USER_NAME}/.xinitrc

echo "alias 'vi'='nvim'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${MY_USER_NAME}/.bashrc

source /home/${MY_USER_NAME}/.bashrc
sed -i "\|/home/${MY_USER_NAME}/user_startup.sh|d" /home/${MY_USER_NAME}/.bash_profile

rm -- "$0"
