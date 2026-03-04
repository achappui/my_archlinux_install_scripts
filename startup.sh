#!/bin/bash
set -e


#01 = HOME_PAPA
#01m = HOME_PAPA_IMAC
#02 = HOME_MAMAN

#01 = HOME_PAPA
MY_01_SSD="/dev/nvme0n1"

MY_01_EFI_SIZE="+1g"
MY_01_SWAP_SIZE="+8g"
MY_01_ROOT_SIZE="0"

MY_01_EFI_PART="/dev/nvme0n1p1"
MY_01_SWAP_PART="/dev/nvme0n1p2"
MY_01_ROOT_PART="/dev/nvme0n1p3"

#01m = HOME_PAPA_IMAC
MY_01m_SSD="/dev/nvme0n1"
MY_01m_HDD="/dev/sda"

MY_01m_SSD_EFI_SIZE="+1g"
MY_01m_SSD_SWAP_SIZE="+1g"
MY_01m_SSD_ROOT_SIZE="0" #0 = tout le reste
MY_01m_HDD_HOME_SIZE="0"

MY_01m_SSD_EFI_PART="/dev/nvme0n1p1"
MY_01m_SSD_SWAP_PART="/dev/nvme0n1p2"
MY_01m_SSD_ROOT_PART="/dev/nvme0n1p3"
MY_01m_HDD_HOME_PART="/dev/sda1"

#02 = HOME_MAMAN
MY_02_SSD="/dev/sda"

MY_02_EFI_SIZE="+1g"
MY_02_SWAP_SIZE="+8g"
MY_02_ROOT_SIZE="0"

MY_02_EFI_PART="/dev/sda1"
MY_02_SWAP_PART="/dev/sda2"
MY_02_ROOT_PART="/dev/sda3"


MY_PREFERED_MIRRORS_REGION=Switzerland,France,Germany,Austria,Italy
MY_CLOCK_REGION=Europe/Zurich
MY_LOCALE="en_US.UTF-8 UTF-8"
MY_LANG=en_US.UTF-8
MY_KEYMAP=us

MY_PACSTRAP_PACKAGES="linux base linux-firmware linux-headers"
MY_PACMAN_PACKAGES="xdg-utils swaybg xdg-desktop-portal-wlr xorg-xwayland xdg-desktop-portal xdg-desktop-portal-gtk gzip bzip2 xz p7zip htop nftables sway fuzzel wayland wayland-protocols mousepad foot grim slurp openssl openssh imlib2 wl-clipboard sudo ripgrep gd dbus nvim pipewire pipewire-pulse wireplumber networkmanager mpv firefox feh zip unzip tar ntfs-3g exfat-utils fuse-exfat dosfstools btrfs-progs xfsprogs e2fsprogs base-devel gcc make curl wget grub efibootmgr docker-buildx intel-ucode man-db man-pages texinfo git python python-pip docker docker-compose noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation ttf-nerd-fonts-symbols thunar"
MY_YAY_PACKAGES="pinta brave-bin google-chrome"

MY_HOSTNAME=""
MY_ROOT_PASSWORD=""
MY_USER=""
MY_USER_PASSWORD=""
MY_WHICH_COMPUTER="" #home_papa home_maman ou home_papa_imac

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

ask_choice() {
    VAR_NAME=$1

    while true; do
        echo "Select which computer:"
        echo "1) home_papa"
        echo "2) home_maman"
        echo "3) home_papa_imac"
        printf "Enter choice (1-3): "
        read CHOICE

        case "$CHOICE" in
            1)
                eval "$VAR_NAME='home_papa'"
                break
                ;;
            2)
                eval "$VAR_NAME='home_maman'"
                break
                ;;
            3)
                eval "$VAR_NAME='home_papa_imac'"
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# --- 2️⃣ Inputs utilisateur ---
ask_input "Enter Hostname" MY_HOSTNAME
ask_password "Enter Root Password" MY_ROOT_PASSWORD
ask_input "Enter User Name" MY_USER
ask_password "Enter User Password" MY_USER_PASSWORD
ask_choice MY_WHICH_COMPUTER

sed -i "/^set -e/a\\
MY_CLOCK_REGION='${MY_CLOCK_REGION}'\\
MY_LOCALE='${MY_LOCALE}'\\
MY_LANG='${MY_LANG}'\\
MY_KEYMAP='${MY_KEYMAP}'\\
MY_ROOT_PASSWORD='${MY_ROOT_PASSWORD}'\\
MY_USER='${MY_USER}'\\
MY_USER_PASSWORD='${MY_USER_PASSWORD}'\\
MY_HOSTNAME='${MY_HOSTNAME}'\\
MY_WHICH_COMPUTER='${MY_WHICH_COMPUTER}'\\
MY_PACMAN_PACKAGES='${MY_PACMAN_PACKAGES}'" chroot_startup.sh

sed -i "/^set -e/a\\
MY_WHICH_COMPUTER='${MY_WHICH_COMPUTER}'\\
MY_USER='${MY_USER}'" user_startup.sh

pacman-key --init
pacman-key --populate archlinux
timedatectl set-ntp true
reflector --country ${MY_PREFERED_MIRRORS_REGION} \
  --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm --needed gptfdisk

if [ ${MY_WHICH_COMPUTER} = "home_papa" ]; then
    read -r -p "Type YES pour confirmer le wipe de ${MY_01_SSD}: " confirm
    if [ "${confirm}" = "YES" ]; then
        sgdisk --zap-all "${MY_01_SSD}"
    else
        echo "Annulé."
    fi
	sgdisk -n 0:0:${MY_01_EFI_SIZE} -t 0:ef00 -c 0:"EFI" ${MY_01_SSD}
	sgdisk -n 0:0:${MY_01_SWAP_SIZE} -t 0:8200 -c 0:"swap" ${MY_01_SSD}
	sgdisk -n 0:0:${MY_01_ROOT_SIZE} -t 0:8300 -c 0:"root" ${MY_01_SSD}

	mkfs.ext4 -F ${MY_01_ROOT_PART}
	mkswap -f ${MY_01_SWAP_PART}
	mkfs.fat -F 32 ${MY_01_EFI_PART}

	mount ${MY_01_ROOT_PART} /mnt
	mount --mkdir ${MY_01_EFI_PART} /mnt/boot
	swapon ${MY_01_SWAP_PART}
fi

if [ ${MY_WHICH_COMPUTER} = "home_maman" ]; then
    read -r -p "Type YES pour confirmer le wipe de ${MY_02_SSD}: " confirm
    if [ "${confirm}" = "YES" ]; then
        sgdisk --zap-all "${MY_02_SSD}"
    else
        echo "Annulé."
    fi
	sgdisk -n 0:0:${MY_02_EFI_SIZE} -t 0:ef00 -c 0:"EFI" ${MY_02_SSD}
	sgdisk -n 0:0:${MY_02_SWAP_SIZE} -t 0:8200 -c 0:"swap" ${MY_02_SSD}
	sgdisk -n 0:0:${MY_02_ROOT_SIZE} -t 0:8300 -c 0:"root" ${MY_02_SSD}

	mkfs.ext4 -F ${MY_02_ROOT_PART}
	mkswap -f ${MY_02_SWAP_PART}
	mkfs.fat -F 32 ${MY_02_EFI_PART}

	mount ${MY_02_ROOT_PART} /mnt
	mount --mkdir ${MY_02_EFI_PART} /mnt/boot
	swapon ${MY_02_SWAP_PART}
fi

if [ ${MY_WHICH_COMPUTER} = "home_papa_imac" ]; then
    read -r -p "Type YES pour confirmer le wipe de ${MY_01m_SSD}: " confirm
    if [ "${confirm}" = "YES" ]; then
        sgdisk --zap-all "${MY_01m_SSD}"
    else
        echo "Annulé."
    fi
    read -r -p "Type YES pour confirmer le wipe de ${MY_01m_HDD}: " confirm
    if [ "${confirm}" = "YES" ]; then
        sgdisk --zap-all "${MY_01m_HDD}"
    else
        echo "Annulé."
    fi

	sgdisk -n 0:0:${MY_02_EFI_SIZE} -t 0:ef00 -c 0:"EFI" ${MY_01m_SSD}
	sgdisk -n 0:0:${MY_02_SWAP_SIZE} -t 0:8200 -c 0:"swap" ${MY_01m_SSD}
	sgdisk -n 0:0:${MY_02_ROOT_SIZE} -t 0:8300 -c 0:"root" ${MY_01m_SSD}
	sgdisk -n 0:0:${MY_02_HOME_SIZE} -t 0:8300 -c 0:"home" ${MY_01m_HDD}

	mkfs.ext4 -F ${MY_01m_SSD_ROOT_PART}
	mkfs.ext4 -F ${MY_01m_HDD_HOME_PART}
	mkswap -f ${MY_01m_SSD_SWAP_PART}
	mkfs.fat -F 32 ${MY_01m_SSD_EFI_PART}

	mount ${MY_01m_SSD_ROOT_PART} /mnt
	mount --mkdir ${MY_01m_HDD_HOME_PART} /mnt/home
	mount --mkdir ${MY_01m_SSD_EFI_PART} /mnt/boot
	swapon ${MY_01m_SSD_SWAP_PART}
fi

pacstrap -K /mnt ${MY_PACSTRAP_PACKAGES}
genfstab -U /mnt >> /mnt/etc/fstab
cp chroot_startup.sh /mnt/chroot_startup.sh
cp user_startup.sh /mnt/user_startup.sh
arch-chroot /mnt /bin/bash chroot_startup.sh
rm /mnt/chroot_startup.sh
umount -R /mnt
reboot
