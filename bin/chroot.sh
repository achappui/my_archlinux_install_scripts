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

source /root/env.sh
source /root/profile.sh

#Setup basic things
ln -sf /usr/share/zoneinfo/${MY_CLOCK_REGION} /etc/localtime
hwclock --systohc
sed -i "/^#${MY_LOCALE}/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=${MY_LANG}" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo ${MY_HOSTNAME} > /etc/hostname
echo "root:${MY_ROOT_PASSWORD}" | chpasswd

#Setup packages and user
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/base.list")
pacman -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/desktops.sway.list")
npm install -g typescript stylelint

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers

sudo -u ${MY_USER} -H bash -c "git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay"
sudo -u ${MY_USER} -H bash -c "makepkg --noconfirm --needed"
pacman -U --noconfirm "/home/${MY_USER}/yay"/*.pkg.tar.zst
rm -rf /home/${MY_USER}/yay
yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/desktops.sway.aur.list")

pacman -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/drivers/${CPU_DRIVERS}.list")

if grep -q ".aur" ${GPU_DRIVERS}; then
    yay -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/drivers/${GPU_DRIVERS}.list")
else
    pacman -Syu --noconfirm --needed $(grep -vE '^\s*#|^\s*$' "/packages/drivers/${GPU_DRIVERS}.list")
fi


#Setup cache policies
systemctl enable paccache.timer
paccache -rk1
journalctl --vacuum-size=100M

#Setup network wired and wifi
systemctl enable systemd-networkd systemd-resolved

mkdir -p /etc/systemd/network

MY_WIRED_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1)
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=${MY_WIRED_INTERFACE}

[Network]
DHCP=yes
EOF

if [ -n "${MY_IS_WIFI_SETUP}" ]; then
MY_WIFI_INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
mkdir -p /etc/iwd
cat <<'EOF' >> /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
mkdir -p /var/lib/iwd
cat <<EOF > /var/lib/iwd/${MY_WIFI_NAME}.psk
[Security]
Passphrase=${MY_WIFI_PASSWORD}
EOF
chmod 600 /var/lib/iwd/${MY_WIFI_NAME}.psk
chown root:root /var/lib/iwd/${MY_WIFI_NAME}.psk
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=${MY_WIFI_INTERFACE}

[Network]
DHCP=yes
EOF
fi

if [ -n "${MY_IS_WIFI_ACTIVATED}" ]; then
    systemctl enable iwd
fi

#Setup docker
systemctl enable docker
usermod -aG docker ${MY_USER}
mkdir -p /home/${MY_USER}/.docker-data
mkdir -p /etc/docker/
cat <<EOF >> /etc/docker/daemon.json
{
  "data-root": "/home/${MY_USER}/.docker-data"
}
EOF

#Setup fonts
mkdir -p /tmp/NerdFont
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/NerdFont/JetBrainsMono.zip
unzip /tmp/NerdFont/JetBrainsMono.zip -d /tmp/NerdFont
mkdir -p /usr/share/fonts/TTF
cp /tmp/NerdFont/*.ttf /usr/share/fonts/TTF/
fc-cache -fv
rm -rf /tmp/NerdFont

#Fix sound parasite
mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf

#Setup Sway start after login
mv /user.sh /home/${MY_USER}/user.sh
chmod +x /home/${MY_USER}/user.sh
echo "/home/${MY_USER}/user.sh" >> /home/${MY_USER}/.bash_profile
cat <<'EOF' >> /home/${MY_USER}/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

#Copying user configs
mkdir -p /home/${MY_USER}/.config/
cp -r /config/* /home/${MY_USER}/.config
rm -r /config

for item in "${SWAY_MONITORS[@]}"; do
    echo "$item" >> /home/${MY_USER}/.config/sway/config
done

# Set ownership of user home and configs
chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

# Install bootloader and generate config
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
