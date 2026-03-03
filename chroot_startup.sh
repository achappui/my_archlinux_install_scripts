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

# if [ ${MY_IS_IMAC} = "true" ]; then
#     nvram SystemAudioVolume=" "
# fi

pacman -Syu --noconfirm --needed ${MY_PACMAN_PACKAGES}

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd

mv /user_startup.sh /home/${MY_USER}/user_startup.sh
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

#Redirecting the heavy loads on the user big partition rather than saturating root
mkdir -p /home/${MY_USER}/.docker-data
mkdir -p /etc/docker/
cat <<EOF >> /etc/docker/daemon.json
{
  "data-root": "/home/${MY_USER}/.docker-data"
}
EOF

mkdir -p /home/${MY_USER}/.pacman-cache
mv /var/cache/pacman/pkg /home/${MY_USER}/.pacman-cache
ln -s /home/${MY_USER}/.pacman-cache/pkg /var/cache/pacman/pkg


systemctl enable NetworkManager
systemctl enable docker

usermod -aG docker ${MY_USER}

mkdir -p /tmp/NerdFont
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/NerdFont/JetBrainsMono.zip
unzip /tmp/NerdFont/JetBrainsMono.zip -d /tmp/NerdFont
mkdir -p /usr/share/fonts/TTF
cp /tmp/NerdFont/*.ttf /usr/share/fonts/TTF/
fc-cache -fv
rm -rf /tmp/NerdFont

mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf

echo "/home/${MY_USER}/user_startup.sh" >> /home/${MY_USER}/.bash_profile
cat <<'EOF' >> /home/${MY_USER}/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

mkinitcpio -P
