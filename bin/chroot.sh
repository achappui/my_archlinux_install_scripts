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

npm install -g typescript stylelint

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd

mv /user_startup.sh /home/${MY_USER}/user_startup.sh
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
sudo -u chad -H bash -c "makepkg -si --dir /home/${MY_USER}/yay"
rm -rf /home/${MY_USER}/yay

yay -Syu --noconfirm --needed ${MY_YAY_PACKAGES}

if [ grep ".aur" ${DRIVERS} != "" ]; then
    yay -Syu --noconfirm --needed ${MY_YAY_PACKAGES}
fi

else [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    pacman -Syu --noconfirm --needed
fi


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


#Setup network wired and wifi
systemctl enable --now systemd-networkd systemd-resolved

mkdir -p /etc/systemd/network
MY_WIRED_INTERFACE=$(networkctl | awk '/ether/ {print $2; exit}')
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=${MY_WIRED_INTERFACE}

[Network]
DHCP=yes
EOF
systemctl restart systemd-networkd

if [ "${MY_IS_WIFI}" = "true" ]; then
    pacman -Syu --noconfirm iwd
    systemctl enable --now iwd
    mkdir -p /etc/iwd
cat <<'EOF' >> /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
    systemctl restart iwd
    mkdir -p /var/lib/iwd
cat <<EOF > /var/lib/iwd/${MY_WIFI_NAME}.psk
[Security]
Passphrase=${MY_WIFI_PASSWORD}
EOF
    chmod 600 /var/lib/iwd/${MY_WIFI_NAME}.psk
    chown root:root /var/lib/iwd/${MY_WIFI_NAME}.psk

    MY_WIFI_INTERFACE=$(iwctl device list | grep station | awk '{print $2}')
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=${MY_WIFI_INTERFACE}

[Network]
DHCP=yes
EOF
    systemctl restart systemd-networkd
    systemctl restart iwd
fi

#Setup docker
systemctl enable docker

usermod -aG docker ${MY_USER}

#Setup fonts
mkdir -p /tmp/NerdFont
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/NerdFont/JetBrainsMono.zip
unzip /tmp/NerdFont/JetBrainsMono.zip -d /tmp/NerdFont
mkdir -p /usr/share/fonts/TTF
cp /tmp/NerdFont/*.ttf /usr/share/fonts/TTF/
fc-cache -fv
rm -rf /tmp/NerdFont

#Setup je sais pas
mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf

# echo "/home/${MY_USER}/user_startup.sh" >> /home/${MY_USER}/.bash_profile

#Setup Sway autoStart
cat <<'EOF' >> /home/${MY_USER}/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

#Copying user configs
mkdir -p /home/${MY_USER}/.config/
cp -r /config/* /home/${MY_USER}/.config
rm -r /config

if [ ${MY_WHICH_COMPUTER} = "home_papa" ]; then
    echo "output DP-4 pos 0 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
    echo "output HDMI-A-0 pos 1920 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
elif [ ${MY_WHICH_COMPUTER} = "home_maman" ]; then
    echo "output HDMI-A-1 pos 0 0 res 1920x1200@60Hz" >> /home/${MY_USER}/.config/sway/config
    echo "output DVI-D-1 pos 1920 0 res 1680x1050@60Hz" >> /home/${MY_USER}/.config/sway/config
elif [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    echo "output DP-3 pos 0 0 res 1920x1080@60Hz" >> /home/${MY_USER}/.config/sway/config
fi


chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

mkinitcpio -P
