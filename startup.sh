#!/bin/bash
set -e

MY_ROOT_SIZE="30G"
MY_SWAP_SIZE="2G"
MY_EFI_SIZE="1G"

MY_DISK_NAME=/dev/sda
MY_PARTITION_EFI=${MY_DISK_NAME}1
MY_PARTITION_SWAP=${MY_DISK_NAME}2
MY_PARTITION_ROOT=${MY_DISK_NAME}3

MY_PREFERED_MIRRORS_REGION=Switzerland,France,Germany,Austria,Italy
MY_CLOCK_REGION=Europe/Zurich
MY_LOCALE="en_US.UTF-8 UTF-8"
MY_LANG=en_US.UTF-8
MY_KEYMAP=us

MY_PACSTRAP_PACKAGES="linux base linux-firmware linux-headers"
MY_PACMAN_PACKAGES="xdg-desktop-portal-wlr xorg-xwayland xdg-desktop-portal xdg-desktop-portal-gtk gzip bzip2 xz p7zip htop nftables sway fuzzel wayland wayland-protocols mousepad foot grim slurp openssl openssh imlib2 wl-clipboard sudo ripgrep gd dbus nvim pipewire pipewire-pulse wireplumber networkmanager mpv firefox feh zip unzip tar ntfs-3g exfat-utils fuse-exfat dosfstools btrfs-progs xfsprogs e2fsprogs base-devel gcc make curl wget grub efibootmgr docker-buildx intel-ucode man-db man-pages texinfo git python python-pip docker docker-compose noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation ttf-nerd-fonts-symbols thunar"
MY_YAY_PACKAGES="pinta brave-bin google-chrome"

MY_NVIDIA_MAXWELL_TO_VOLTA_PACKAGES="linux-headers nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils"
MY_INTEL_IRIS_PRO_GRAPHICS_PACKAGES="mesa libva intel-ucode"

while true; do
    printf "Enter Hostname: "
    read MY_HOSTNAME
    if [ -n "${MY_HOSTNAME}" ]; then
        break
    else
        echo "Hostname cannot be empty. Please try again."
    fi
done

while true; do
    printf "Enter Root Password: "
    stty -echo
    read MY_ROOT_PASSWORD
    stty echo
    echo
    if [ -n "${MY_ROOT_PASSWORD}" ]; then
        break
    else
        echo "Root password cannot be empty. Please try again."
    fi
done

while true; do
    printf "Enter User Name: "
    read MY_USER
    if [ -n "${MY_USER}" ]; then
        break
    else
        echo "User name cannot be empty. Please try again."
    fi
done

while true; do
    printf "Enter User Password: "
    stty -echo
    read MY_USER_PASSWORD
    stty echo
    echo
    if [ -n "${MY_USER_PASSWORD}" ]; then
        break
    else
        echo "User password cannot be empty. Please try again."
    fi
done

while true; do
    printf "Is this an iMac? [y/n]: "
    read ANSWER
    case "${ANSWER}" in
        y|Y)
            MY_IS_IMAC="true"
            break
            ;;
        n|N)
            MY_IS_IMAC="false"
            break
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done

while true; do
    echo "Choose GPU driver:"
    echo "1) nvidia_maxwell_to_volta"
    echo "2) intel_iris_pro_graphics"
    printf "Enter 1 or 2: "
    read DRIVER_CHOICE
    case "${DRIVER_CHOICE}" in
        1)
            MY_DRIVER="nvidia_maxwell_to_volta"
            break
            ;;
        2)
            MY_DRIVER="intel_iris_pro_graphics"
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

sed -i "/^set -e/a\\
MY_CLOCK_REGION='${MY_CLOCK_REGION}'\\
MY_LOCALE='${MY_LOCALE}'\\
MY_LANG='${MY_LANG}'\\
MY_KEYMAP='${MY_KEYMAP}'\\
MY_ROOT_PASSWORD='${MY_ROOT_PASSWORD}'\\
MY_USER='${MY_USER}'\\
MY_USER_PASSWORD='${MY_USER_PASSWORD}'\\
MY_HOSTNAME='${MY_HOSTNAME}'\\
MY_IS_IMAC='${MY_IS_IMAC}'\\
MY_PACMAN_PACKAGES='${MY_PACMAN_PACKAGES}'" chroot_startup.sh

sed -i "/^set -e/a\\
MY_YAY_PACKAGES='${MY_YAY_PACKAGES}'\\
MY_NVIDIA_MAXWELL_TO_VOLTA_PACKAGES='${MY_NVIDIA_MAXWELL_TO_VOLTA_PACKAGES}'\\
MY_INTEL_IRIS_PRO_GRAPHICS_PACKAGES='${MY_INTEL_IRIS_PRO_GRAPHICS_PACKAGES}'\\
MY_USER='${MY_USER}'" user_startup.sh


pacman-key --init
pacman-key --populate archlinux
timedatectl set-ntp true
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

pacstrap -K /mnt ${MY_PACSTRAP_PACKAGES}
genfstab -U /mnt >> /mnt/etc/fstab
cp chroot_startup.sh /mnt/chroot_startup.sh
cp user_startup.sh /mnt/user_startup.sh
arch-chroot /mnt /bin/bash chroot_startup.sh
rm /mnt/chroot_startup.sh
umount -R /mnt
reboot
