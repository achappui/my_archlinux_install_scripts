#!/bin/bash
set -e



ln -sf /usr/share/zoneinfo/${MY_CLOCK_REGION} /etc/localtime
hwclock --systohc

sed -i "/^#${MY_LOCALE}/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=${MY_LANG}" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo ${MY_HOSTNAME} > /etc/hostname
echo "root:${MY_ROOT_PASSWORD}" | chpasswd

sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

pacman -Syu --noconfirm --needed ${MY_PACMAN}

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash ${MY_MAIN_USER}
echo "${MY_MAIN_USER}:${MY_MAIN_USER_PASSWORD}" | chpasswd

mv /user_startup.sh /home/${MY_MAIN_USER}/user_startup.sh
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

systemctl enable NetworkManager
systemctl enable docker

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

echo "/home/${MY_MAIN_USER}/user_startup.sh" >> /home/${MY_MAIN_USER}/.bash_profile
cat <<'EOF' >> /home/${MY_MAIN_USER}/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

chown -R ${MY_MAIN_USER}:${MY_MAIN_USER} /home/${MY_MAIN_USER}

mkinitcpio -P
