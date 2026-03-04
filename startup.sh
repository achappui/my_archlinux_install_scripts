#!/bin/bash
set -e


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

MY_HOSTNAME=""
MY_ROOT_PASSWORD=""
MY_USER=""
MY_USER_PASSWORD=""


MY_WHICH_COMPUTER="false"

ask_input() {
    PROMPT=$1
    VAR_NAME=$2
    while true; do
        printf "%s: " "${PROMPT}"
        read VALUE
        if [ -n "${VALUE}" ]; then
            eval "${VAR_NAME}='${VALUE}'"
            break
        else
            echo "Cannot be empty. Try again."
        fi
    done
}

ask_password() {
    PROMPT=$1
    VAR_NAME=$2
    while true; do
        printf "%s: " "${PROMPT}"
        stty -echo
        read VALUE
        stty echo
        echo
        if [ -n "${VALUE}" ]; then
            eval "${VAR_NAME}='${VALUE}'"
            break
        else
            echo "Cannot be empty. Try again."
        fi
    done
}

ask_boolean() {
    PROMPT=$1
    VAR_NAME=$2
    while true; do
        printf "%s [y/n]: " "${PROMPT}"
        read VALUE
        case "${VALUE}" in
            y|Y) eval "${VAR_NAME}='true'"; break ;;
            n|N) eval "${VAR_NAME}='false'"; break ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# --- 2️⃣ Inputs utilisateur ---
ask_input "Enter Hostname" MY_HOSTNAME
ask_password "Enter Root Password" MY_ROOT_PASSWORD
ask_input "Enter User Name" MY_USER
ask_password "Enter User Password" MY_USER_PASSWORD
ask_boolean "Is this an iMac?" MY_IS_IMAC

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
MY_IS_IMAC='${MY_IS_IMAC}'\\
MY_USER='${MY_USER}'" user_startup.sh

pacman-key --init
pacman-key --populate archlinux
timedatectl set-ntp true
reflector --country ${MY_PREFERED_MIRRORS_REGION} \
  --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm --needed gptfdisk

# ----- CREATE PARTITIONS -----
# EFI
sgdisk -n 0:0:+${MY_EFI_SIZE} -t 0:ef00 -c 0:"${MY_EFI_LABEL}" /dev/${MY_EFI_DISK_LOCATION}

# ROOT
sgdisk -n 0:0:+${MY_ROOT_SIZE} -t 0:8300 -c 0:"${MY_ROOT_LABEL}" /dev/${MY_ROOT_DISK_LOCATION}

# USER
sgdisk -n 0:0:+${MY_USER_SIZE} -t 0:8300 -c 0:"${MY_USER_LABEL}" /dev/${MY_USER_DISK_LOCATION}

# SWAP
sgdisk -n 0:0:+${MY_SWAP_SIZE} -t 0:8200 -c 0:"${MY_SWAP_LABEL}" /dev/${MY_SWAP_DISK_LOCATION}

mkfs.ext4 -F ${MY_ROOT_PARTITION}
mkfs.ext4 -F ${MY_USER_PARTITION}
mkswap -f ${MY_SWAP_PARTITION}
mkfs.fat -F 32 ${MY_EFI_PARTITION}

mount ${MY_ROOT_PARTITION} /mnt
mount --mkdir ${MY_USER_PARTITION} /mnt/home
mount --mkdir ${MY_EFI_PARTITION} /mnt/boot
swapon ${MY_SWAP_PARTITION}

pacstrap -K /mnt ${MY_PACSTRAP_PACKAGES}
genfstab -U /mnt >> /mnt/etc/fstab
cp chroot_startup.sh /mnt/chroot_startup.sh
cp user_startup.sh /mnt/user_startup.sh
arch-chroot /mnt /bin/bash chroot_startup.sh
rm /mnt/chroot_startup.sh
umount -R /mnt
reboot
