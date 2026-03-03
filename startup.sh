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
MY_IS_IMAC="false"
MY_DRIVER=""

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

ask_choice() {
    PROMPT=$1
    VAR_NAME=$2
    CHOICE1=$3
    CHOICE2=$4
    while true; do
        echo "${PROMPT}"
        echo "1) ${CHOICE1}"
        echo "2) ${CHOICE2}"
        printf "Enter 1 or 2: "
        read VALUE
        case "${VALUE}" in
            1) eval "${VAR_NAME}='${CHOICE1}'"; break ;;
            2) eval "${VAR_NAME}='${CHOICE2}'"; break ;;
            *) echo "Invalid choice, try again." ;;
        esac
    done
}

# --- 2️⃣ Inputs utilisateur ---
ask_input "Enter Hostname" MY_HOSTNAME
ask_password "Enter Root Password" MY_ROOT_PASSWORD
ask_input "Enter User Name" MY_USER
ask_password "Enter User Password" MY_USER_PASSWORD
ask_boolean "Is this an iMac?" MY_IS_IMAC
ask_choice "Choose GPU driver" MY_DRIVER "nvidia_maxwell_to_volta" "intel_iris_pro_graphics"

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

wipe_disks() {
    echo "Available disks:"
    COUNT=0
    DISK_NAMES=""
    for D in $(lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$3=="disk" && $2!="0B" {print $1}'); do
        COUNT=$((COUNT+1))
        echo "${COUNT}) ${D} ($(lsblk -d -no SIZE /dev/$D))"
        DISK_NAMES="${DISK_NAMES} ${D}"
    done

    i=1
    for D in $DISK_NAMES; do
        while true; do
            printf "Do you want to erase disk %s? [y/n]: " "$D"
            read ANSWER
            case "$ANSWER" in
                y|Y)
                    echo "Erasing /dev/$D..."
                    sgdisk --zap-all /dev/$D
                    echo "Done."
                    break
                    ;;
                n|N)
                    echo "Skipping /dev/$D."
                    break
                    ;;
                *)
                    echo "Please answer y or n."
                    ;;
            esac
        done
        i=$((i+1))
    done
}

wipe_disks

# Variables
MY_EFI_DISK_LOCATION=""
MY_ROOT_DISK_LOCATION=""
MY_USER_DISK_LOCATION=""
MY_SWAP_DISK_LOCATION=""
MY_EFI_SIZE=""
MY_ROOT_SIZE=""
MY_USER_SIZE=""
MY_SWAP_SIZE=""
MY_EFI_LABEL=""
MY_ROOT_LABEL=""
MY_USER_LABEL=""
MY_SWAP_LABEL=""
MY_EFI_PARTITION=""
MY_ROOT_PARTITION=""
MY_USER_PARTITION=""
MY_SWAP_PARTITION=""

# ----- FUNCTIONS -----

list_disks() {
    echo "Available disks:"
    COUNT=0
    DISK_NAMES=""
    for D in $(lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$3=="disk" && $2!="0B" {print $1}'); do
        COUNT=$((COUNT+1))
        echo "${COUNT}) ${D}"
        DISK_NAMES="${DISK_NAMES} ${D}"
    done
}

select_disk() {
    while true; do
        printf "Select disk by number: "
        read CHOICE
        case $CHOICE in
            ''|*[!0-9]*) echo "Invalid input, must be a number"; continue ;;
        esac
        if [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$COUNT" ]; then
            i=1
            for D in $DISK_NAMES; do
                if [ "$i" -eq "$CHOICE" ]; then
                    DISK_SELECTED="$D"
                    return
                fi
                i=$((i+1))
            done
        else
            echo "Number out of range, try again."
        fi
    done
}

ask_size() {
    PROMPT=$1
    VAR_NAME=$2
    while true; do
        printf "%s: " "$PROMPT"
        read VALUE
        VALUE=$(echo "$VALUE" | tr -d '[:space:]')

        # Accept 'all'
        if [ "$VALUE" = "all" ]; then
            eval "$VAR_NAME='all'"
            return
        fi

        # Validate format number + m or g
        if echo "$VALUE" | grep -Eq '^[0-9]+[mMgG]$'; then
            eval "$VAR_NAME='$VALUE'"
            return
        else
            echo "Invalid size. Use format like 512M, 20G, or 'all' for remaining space."
        fi
    done
}

ask_label() {
    PROMPT=$1
    VAR_NAME=$2
    while true; do
        printf "%s: " "$PROMPT"
        read LABEL
        LABEL=$(echo "$LABEL" | tr -d '[:space:]')
        if [ -n "$LABEL" ]; then
            eval "$VAR_NAME='$LABEL'"
            return
        else
            echo "Label cannot be empty."
        fi
    done
}

get_partition_name() {
    LABEL=$1
    eval "$2=\$(lsblk -lno NAME,LABEL | grep \"$LABEL\" | awk '{print \"/dev/\"\$1}')"
}

# ----- MAIN LOOP -----
while true; do

    echo
    list_disks

    echo "--- EFI Partition ---"
    select_disk
    MY_EFI_DISK_LOCATION="$DISK_SELECTED"
    ask_size "Enter EFI partition size (e.g., 512M)" MY_EFI_SIZE
    ask_label "Enter EFI partition label" MY_EFI_LABEL

    echo "--- ROOT Partition ---"
    select_disk
    MY_ROOT_DISK_LOCATION="$DISK_SELECTED"
    ask_size "Enter ROOT partition size (e.g., 20G)" MY_ROOT_SIZE
    ask_label "Enter ROOT partition label" MY_ROOT_LABEL

    echo "--- USER Partition ---"
    select_disk
    MY_USER_DISK_LOCATION="$DISK_SELECTED"
    ask_size "Enter USER partition size (e.g., rest of disk)" MY_USER_SIZE
    ask_label "Enter USER partition label" MY_USER_LABEL

    echo "--- SWAP Partition ---"
    select_disk
    MY_SWAP_DISK_LOCATION="$DISK_SELECTED"
    ask_size "Enter SWAP partition size (e.g., 8G)" MY_SWAP_SIZE
    ask_label "Enter SWAP partition label" MY_SWAP_LABEL

    # Show summary
    echo
    echo "=== Partition Summary ==="
    echo "EFI    : Disk=${MY_EFI_DISK_LOCATION} Size=${MY_EFI_SIZE} Label=${MY_EFI_LABEL}"
    echo "ROOT   : Disk=${MY_ROOT_DISK_LOCATION} Size=${MY_ROOT_SIZE} Label=${MY_ROOT_LABEL}"
    echo "USER   : Disk=${MY_USER_DISK_LOCATION} Size=${MY_USER_SIZE} Label=${MY_USER_LABEL}"
    echo "SWAP   : Disk=${MY_SWAP_DISK_LOCATION} Size=${MY_SWAP_SIZE} Label=${MY_SWAP_LABEL}"
    printf "Confirm these choices? [y/n]: "
    read CONFIRM
    case "$CONFIRM" in
        y|Y) break ;;
        n|N) echo "Restarting partition selection..." ;;
        *) echo "Please answer y or n." ;;
    esac
done

# ----- CREATE PARTITIONS -----
# EFI
sgdisk -n 0:0:+${MY_EFI_SIZE} -t 0:ef00 -c 0:"${MY_EFI_LABEL}" /dev/${MY_EFI_DISK_LOCATION}

# ROOT
sgdisk -n 0:0:+${MY_ROOT_SIZE} -t 0:8300 -c 0:"${MY_ROOT_LABEL}" /dev/${MY_ROOT_DISK_LOCATION}

# USER
sgdisk -n 0:0:+${MY_USER_SIZE} -t 0:8300 -c 0:"${MY_USER_LABEL}" /dev/${MY_USER_DISK_LOCATION}

# SWAP
sgdisk -n 0:0:+${MY_SWAP_SIZE} -t 0:8200 -c 0:"${MY_SWAP_LABEL}" /dev/${MY_SWAP_DISK_LOCATION}

# ----- DETECT ACTUAL PARTITION NAMES -----
get_partition_name "$MY_EFI_LABEL" MY_EFI_PARTITION
get_partition_name "$MY_ROOT_LABEL" MY_ROOT_PARTITION
get_partition_name "$MY_USER_LABEL" MY_USER_PARTITION
get_partition_name "$MY_SWAP_LABEL" MY_SWAP_PARTITION

echo
echo "=== Partition Device Nodes ==="
echo "EFI    : $MY_EFI_PARTITION"
echo "ROOT   : $MY_ROOT_PARTITION"
echo "USER   : $MY_USER_PARTITION"
echo "SWAP   : $MY_SWAP_PARTITION"

# Done, partitions created and variables set

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
