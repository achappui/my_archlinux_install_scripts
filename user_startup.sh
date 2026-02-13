#!/bin/bash
set -e

systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber

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
xset r rate 180 50 &
picom &
dash ~/.config/chadwm/scripts/bar.sh &
while type chadwm >/dev/null; do chadwm && continue || break; done" > /home/${MY_USER_NAME}/.xinitrc

echo "alias 'vi'='nvim'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'sudo'='sudo '" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'chadwm-c'='nvim /home/${MY_USER_NAME}/.config/chadwm/chadwm/config.def.h'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'chadwm-m'='sudo make -C /home/${MY_USER_NAME}/.config/chadwm/chadwm clean install'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'dmenu-c'='nvim /home/${MY_USER_NAME}/.config/dmenu/config.h'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'dmenu-m'='sudo make -C /home/${MY_USER_NAME}/.config/dmenu clean install'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'st-c'='nvim /home/${MY_USER_NAME}/.config/st/config.h'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'st-m'='sudo make -C /home/${MY_USER_NAME}/.config/st clean install'" >> /home/${MY_USER_NAME}/.bashrc
echo "alias 'rel'='xrdb merge pathToXresourcesFile && kill -USR1 $(pidof st)'" >> /home/${MY_USER_NAME}/.bashrc

source /home/${MY_USER_NAME}/.bashrc
sed -i "\|/home/${MY_USER_NAME}/user_startup.sh|d" /home/${MY_USER_NAME}/.bash_profile

git clone https://github.com/NvChad/starter /home/${MY_MAIN_USER}/.config/nvim && nvim



rm -- "$0"
