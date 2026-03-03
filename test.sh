#!/bin/sh
# Interactive GPT partitioning with sgdisk including swap
# Works on Arch Linux live ISO

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