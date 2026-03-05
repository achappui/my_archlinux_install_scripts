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

pacman -Syu --noconfirm --needed ${MY_PACMAN_PACKAGES}

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd

mv /user_startup.sh /home/${MY_USER}/user_startup.sh
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

if [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
  mkdir -p /home/${MY_USER}/.docker-data
  mkdir -p /etc/docker/
cat <<EOF >> /etc/docker/daemon.json
{
  "data-root": "/home/${MY_USER}/.docker-data"
}
EOF
  pacman -Syu --noconfirm pacman-contrib
  systemctl enable --now paccache.timer
  paccache -rk1
  journalctl --vacuum-size=100M 
fi

if [ "${MY_IS_WIFI}" = "true" ]; then
    pacman -Syu --noconfirm iw iwd
    mkdir -p /var/lib/iwd
cat <<EOF > /var/lib/iwd/${MY_WIFI_NAME}.psk
[Security]
Passphrase=${MY_WIFI_PASSWORD}
EOF
    chmod 600 /var/lib/iwd/${MY_WIFI_NAME}.psk
    chown root:root /var/lib/iwd/${MY_WIFI_NAME}.psk
    systemctl enable --now iwd
fi

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

echo "sudo /home/${MY_USER}/user_startup.sh" >> /home/${MY_USER}/.bash_profile
cat <<'EOF' >> /home/${MY_USER}/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

mkdir -p /home/${MY_USER}/.config/foot
echo "font = JetBrainsMono Nerd Font:pixelsize=14" > /home/${MY_USER}/.config/foot/foot.ini

mkdir -p /home/${MY_USER}/.config/sway
cp /etc/sway/config /home/${MY_USER}/.config/sway/config
sed -i 's/^set $menu .*/set $menu fuzzel/' /home/${MY_USER}/.config/sway/config
chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

mkinitcpio -P
