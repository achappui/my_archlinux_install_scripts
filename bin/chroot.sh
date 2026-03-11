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

PACMAN_PKGS=(
$(grep -vE '^\s*#|^\s*$' /packages/base.list)
$(grep -vE '^\s*#|^\s*$' /packages/desktops/sway.list)
$(grep -vE '^\s*#|^\s*$' /packages/drivers/${CPU_DRIVERS}.list)
)

if ! echo ${GPU_DRIVERS} | grep -q ".aur"; then
    PACMAN_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/${GPU_DRIVERS}.list))
fi

pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

sudo -u ${MY_USER} git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
sudo -u ${MY_USER} makepkg -s --noconfirm --needed --dir /home/${MY_USER}/yay
pacman -U --noconfirm --needed /home/${MY_USER}/yay/yay-*.pkg.tar.zst
rm -rf /home/${MY_USER}/yay

AUR_PKGS=(
$(grep -vE '^\s*#|^\s*$' /packages/desktops/sway.aur.list)
)

if echo ${GPU_DRIVERS} | grep -q ".aur"; then
    AUR_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/${GPU_DRIVERS}.list))
fi

sudo -u ${MY_USER} yay -S --noconfirm --needed "${AUR_PKGS[@]}"

sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers

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

#Fix sound parasite
mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf

#Setup Sway start after login
mv /user.sh /home/${MY_USER}/user.sh
chmod +x /home/${MY_USER}/user.sh
echo "/home/${MY_USER}/user.sh" >> /home/${MY_USER}/.bash_profile

echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then' >> /home/${MY_USER}/.bash_profile
if echo ${GPU_DRIVERS} | grep -q "nvidia"; then
    echo 'exec sway --unsupported-gpu' >> /home/${MY_USER}/.bash_profile
else
    echo 'exec sway' >> /home/${MY_USER}/.bash_profile
fi
echo 'fi' >> /home/${MY_USER}/.bash_profile

#Copying user configs
mkdir -p /home/${MY_USER}/.config/
cp -r /config/* /home/${MY_USER}/.config
rm -rf /config

for item in "${SWAY_MONITORS[@]}"; do
    echo "$item" >> /home/${MY_USER}/.config/sway/config
done

# Set ownership of user home and configs
chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

#Fix imac auto reboot
if [ "${PROFILE_NAME}" = "home_papa_imac" ]; then
    echo "ARPT" | tee "/proc/acpi/wakeup"
    echo "GIGE" | tee "/proc/acpi/wakeup"
    echo "XHC1" | tee "/proc/acpi/wakeup"
fi

# Install bootloader and generate config
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
