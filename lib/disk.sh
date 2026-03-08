#!/bin/bash
set -e

# =====================================
# Génération des noms de partitions
# =====================================
PARTS=()
declare -A COUNTER
for disk in "${D[@]}"; do
    COUNTER["$disk"]=1
done

for i in "${!PART_NAMES[@]}"; do
    disk="${PART_DISK[$i]}"
    num=${COUNTER[$disk]}

    if [[ "$disk" =~ nvme ]]; then
        part="${disk}p${num}"
    else
        part="${disk}${num}"
    fi

    PARTS+=("$part")
    COUNTER["$disk"]=$((num + 1))
done

# =====================================
# Fonctions génériques
# =====================================
wipe_disks() {
    local disks=("$@")
    for disk in "${disks[@]}"; do
        echo "Type YES to wipe $disk"
        read CONFIRM
        if [[ "$CONFIRM" != "YES" ]]; then
            echo "Cancelled."
            exit 1
        fi
        sgdisk --zap-all "$disk"
    done
}

create_partitions() {
    for i in "${!PARTS[@]}"; do
        sgdisk -n 0:0:${PART_SIZES[$i]} -t 0:${PART_TYPES[$i]} -c 0:"${PART_NAMES[$i]}" "${PART_DISK[$i]}"
    done
}

format_and_mount() {
    for i in "${!PARTS[@]}"; do
        part="${PARTS[$i]}"
        name="${PART_NAMES[$i]}"

        case "$name" in
            EFI)
                mkfs.fat -F32 "$part"
                mount --mkdir "$part" /mnt/boot
                ;;
            swap)
                mkswap -f "$part"
                swapon "$part"
                ;;
            root)
                mkfs.ext4 -F "$part"
                mount "$part" /mnt
                ;;
            home)
                mkfs.ext4 -F "$part"
                mount --mkdir "$part" /mnt/home
                ;;
        esac
    done
}

# =====================================
# Exécution
# =====================================
wipe_disks "${D[@]}"
create_partitions
format_and_mount