#!/bin/bash
set -e



ln -sf /usr/share/zoneinfo/${MY_CLOCK_REGION} /etc/localtime
hwclock --systohc

sed -i "/^#${MY_LOCALE}/s/^#//" /etc/locale.gen
locale-gen
echo "MY_LANG=${MY_LANG}" > /etc/locale.conf
echo "MY_KEYMAP=us" > /etc/vconsole.conf
echo ${MY_HOSTNAME} > /etc/hostname
echo "root:${MY_ROOT_PASSWORD}" | chpasswd


sed -i '/^\#\[multilib\]/s/^#//; /^\#Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

pacman -Syu --noconfirm --needed ${MY_PACMAN}

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay

yay -Syu --noconfirm --needed linux-headers pinta leafpad

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash ${MY_MAIN_USER}
echo "${MY_MAIN_USER}:${MY_MAIN_USER_PASSWORD}" | chpasswd

mv /user_startup.sh /home/${MY_MAIN_USER}/user_startup.sh
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

systemctl enable NetworkManager
systemctl start NetworkManager

systemctl start docker

usermod -aG docker ${MY_MAIN_USER}

mkdir -p /tmp/NerdFont
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/NerdFont/JetBrainsMono.zip
unzip /tmp/NerdFont/JetBrainsMono.zip -d /tmp/NerdFont
mkdir -p /usr/share/fonts/TTF
cp /tmp/NerdFont/*.ttf /usr/share/fonts/TTF/
fc-cache -fv
rm -rf /tmp/NerdFont

mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf

git clone https://github.com/siduck/chadwm --depth 1 /home/${MY_MAIN_USER}/.config/chadwm/
mv /home/${MY_MAIN_USER}/.config/chadwm/eww /home/${MY_MAIN_USER}/.config
make -C /home/${MY_MAIN_USER}/.config/chadwm/chadwm clean install
git clone https://github.com/siduck/st.git /home/${MY_MAIN_USER}/.config/st
make -C /home/${MY_MAIN_USER}/.config/st clean install
git clone https://git.suckless.org/dmenu /home/${MY_MAIN_USER}/.config/dmenu
make -C /home/${MY_MAIN_USER}/.config/dmenu clean install

echo "/home/${MY_MAIN_USER}/user_startup.sh" >> /home/${MY_MAIN_USER}/.bash_profile
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec startx fi' >> /home/${MY_MAIN_USER}/.bash_profile
chown -R ${MY_MAIN_USER}:${MY_MAIN_USER} /home/${MY_MAIN_USER}

mkinitcpio -P
