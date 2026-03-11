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

source ../lib/input.sh
source ../lib/disk.sh

MY_HOSTNAME=""
MY_ROOT_PASSWORD=""
MY_USER=""
MY_USER_PASSWORD=""
MY_PROFILE=""
MY_WIFI_NAME=""
MY_WIFI_PASSWORD=""

# --- 2️⃣ Inputs utilisateur ---
ask_input "Enter Hostname"              MY_HOSTNAME
ask_input "Enter Root Password"         MY_ROOT_PASSWORD
ask_input "Enter User Name"             MY_USER
ask_input "Enter User Password"         MY_USER_PASSWORD
ask_profile "Available profiles:"       MY_PROFILE

source "../profiles/${MY_PROFILE}.sh"

if [ "${MY_IS_WIFI_SETUP}" = "true" ]; then
  ask_input "Enter WiFi Name" MY_WIFI_NAME
  ask_input "Enter WiFi Password" MY_WIFI_PASSWORD
fi

ask_boolean "All disks will be erased"  MY_ERASE_CONFIRMATION

PARTS=()
generate_parts D PART_NAMES PART_DISK PARTS

timedatectl set-ntp true
reflector --country ${MY_PREFERED_MIRRORS_REGION} \
  --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm --needed gptfdisk

wipe_disks "${MY_ERASE_CONFIRMATION}" "${D[@]}"
create_partitions PART_NAMES PART_DISK PART_SIZES PART_TYPES
format_and_mount PARTS PART_NAMES

pacstrap -K /mnt $(grep -vE '^\s*#|^\s*$' "../packages/pacstrap.list")
genfstab -U /mnt >> /mnt/etc/fstab

rm /mnt/etc/resolv.conf
ln -sf /mnt/run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf #DNS
cp chroot.sh /mnt/chroot.sh
cp user.sh /mnt/user.sh
cp -r ../config /mnt/config

cat <<EOF > /mnt/root/env.sh
export MY_HOSTNAME="${MY_HOSTNAME}"
export MY_USER="${MY_USER}"
export MY_USER_PASSWORD="${MY_USER_PASSWORD}"
export MY_ROOT_PASSWORD="${MY_ROOT_PASSWORD}"
export MY_WIFI_NAME="${MY_WIFI_NAME}"
export MY_WIFI_PASSWORD="${MY_WIFI_PASSWORD}"
EOF

cp "../profiles/${MY_PROFILE}.sh" /mnt/root/profile.sh
cp -r "../packages" /mnt/packages

arch-chroot /mnt /bin/bash chroot.sh
rm /mnt/chroot.sh
rm -rf /mnt/root/profile.sh
rm -rf /mnt/root/env.sh
rm -rf /mnt/packages
umount -R /mnt
reboot
