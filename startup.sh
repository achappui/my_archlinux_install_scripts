#!/bin/bash
set -e

MY_ROOT_PASSWORD=
MY_MAIN_USER=
MY_MAIN_USER_PASSWORD=
MY_HOSTNAME=

MY_ROOT_SIZE="20G"
MY_SWAP_SIZE="2G"
MY_EFI_SIZE="1G"

MY_DISK_NAME=/dev/sda
MY_PARTITION_EFI=${MY_DISK_NAME}1
MY_PARTITION_SWAP=${MY_DISK_NAME}2
MY_PARTITION_ROOT=${MY_DISK_NAME}3
MY_PREFERED_MIRRORS_REGION=Switzerland,France,Germany,Austria,Italy
MY_PACSTRAP="linux base linux-firmware linux-headers"
MY_CLOCK_REGION=Europe/Zurich
MY_LOCALE="en_US.UTF-8 UTF-8"
MY_LANG=en_US.UTF-8
MY_KEYMAP=us
MY_PACMAN="xsetroot imlib2 dash picom acpi sudo rofi ripgrep gd dbus xdg-desktop-portal xdg-desktop-portal-gtk xorg-server xorg-xinit xorg-xrandr xf86-input-libinput libx11 libxft libxinerama nvim pipewire pipewire-pulse wireplumber networkmanager mpv firefox lf feh zip unzip tar ntfs-3g exfat-utils fuse-exfat dosfstools btrfs-progs xfsprogs e2fsprogs base-devel gcc make curl wget grub efibootmgr docker-buildx intel-ucode man-db man-pages texinfo git rustup python python-pip nodejs npm docker docker-compose  noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation ttf-nerd-fonts-symbols"

sed -i "/^set -e/a\\
MY_CLOCK_REGION='${MY_CLOCK_REGION}'\\
MY_LOCALE='${MY_LOCALE}'\\
MY_LANG='${MY_LANG}'\\
MY_KEYMAP='${MY_KEYMAP}'\\
MY_ROOT_PASSWORD='${MY_ROOT_PASSWORD}'\\
MY_MAIN_USER='${MY_MAIN_USER}'\\
MY_MAIN_USER_PASSWORD='${MY_MAIN_USER_PASSWORD}'\\
MY_HOSTNAME='${MY_HOSTNAME}'\\
MY_PACMAN='${MY_PACMAN}'" chroot_startup.sh

sed -i "/^set -e/a\\
MY_USER_NAME='${MY_MAIN_USER}'" user_startup.sh

pacman-key --init
pacman-key --populate archlinux
timedatectl
reflector --country ${MY_PREFERED_MIRRORS_REGION} \
  --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm --needed gptfdisk
sgdisk --zap-all ${MY_DISK_NAME}
sgdisk -n 1:0:+${MY_EFI_SIZE} -t 1:ef00 -c 1:"EFI" ${MY_DISK_NAME}
sgdisk -n 2:0:+${MY_SWAP_SIZE} -t 2:8200 -c 2:"swap" ${MY_DISK_NAME}
sgdisk -n 3:0:+${MY_ROOT_SIZE} -t 3:8300 -c 3:"root" ${MY_DISK_NAME}
mkfs.ext4 -F ${MY_PARTITION_ROOT}
mkswap -f ${MY_PARTITION_SWAP}
mkfs.fat -F 32 ${MY_PARTITION_EFI}
mount ${MY_PARTITION_ROOT} /mnt
mount --mkdir ${MY_PARTITION_EFI} /mnt/boot
swapon ${MY_PARTITION_SWAP}
pacstrap -K /mnt ${MY_PACSTRAP}
genfstab -U /mnt >> /mnt/etc/fstab
cp chroot_startup.sh /mnt/chroot_startup.sh
cp user_startup.sh /mnt/user_startup.sh
arch-chroot /mnt /bin/bash chroot_startup.sh
rm /mnt/chroot_startup.sh
umount -R /mnt
reboot
