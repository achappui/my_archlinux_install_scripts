#!/bin/bash
set -euo pipefail

# =====================================
# Fonctions génériques pour les disques
# =====================================

wipe_disks() {
    local auto_confirm="$1"
    shift
    local disks=("$@")
    local disk
    local CONFIRM

    echo "=== Wiping disks ==="
    for disk in "${disks[@]}"; do
        if [ "${auto_confirm}" != "true" ]; then
            echo "Type YES to wipe ${disk}"
            read CONFIRM
            if [[ "${CONFIRM}" != "YES" ]]; then
                echo "Cancelled."
                exit 1
            fi
        fi
        echo "Wiping ${disk}..."
        sgdisk --zap-all "${disk}"
        echo "${disk} wiped."
    done
    echo "All selected disks wiped."
}

create_partitions() {
    local -n names_ref="$1"
    local -n disks_ref="$2"
    local -n sizes_ref="$3"
    local -n types_ref="$4"
    local i

    echo "=== Creating partitions ==="
    for i in "${!names_ref[@]}"; do
        echo "Creating partition '${names_ref[$i]}' on '${disks_ref[$i]}' of size '${sizes_ref[$i]}' with type '${types_ref[$i]}'..."
        sgdisk -n 0:0:${sizes_ref[$i]} -t 0:${types_ref[$i]} -c 0:"${names_ref[$i]}" "${disks_ref[$i]}"
        echo "Partition '${names_ref[$i]}' created."
    done
    echo "All partitions created."
}

format_and_mount() {
    local -n parts_ref="$1"
    local -n names_ref="$2"
    local sorted_parts=()
    local sorted_names=()
    local i

    echo "=== Formatting and mounting partitions ==="

    local order=("root" "home" "swap" "EFI")

    for name_in_order in "${order[@]}"; do
        for i in "${!parts_ref[@]}"; do
            if [[ "${names_ref[$i]}" == "$name_in_order" ]]; then
                sorted_parts+=("${parts_ref[$i]}")
                sorted_names+=("${names_ref[$i]}")
            fi
        done
    done

    for i in "${!sorted_parts[@]}"; do
        local part="${sorted_parts[$i]}"
        local name="${sorted_names[$i]}"
        echo "Processing ${part} (${name})..."

        case "${name}" in
            root)
                echo "Formatting ${part} as ext4 and mounting at /mnt"
                mkfs.ext4 -F "${part}"
                mount "${part}" /mnt
                ;;
            home)
                echo "Formatting ${part} as ext4 and mounting at /mnt/home"
                mkfs.ext4 -F "${part}"
                mount --mkdir "${part}" /mnt/home
                ;;
            swap)
                echo "Formatting ${part} as swap"
                mkswap -f "${part}"
                swapon "${part}"
                ;;
            EFI)
                echo "Formatting ${part} as FAT32 and mounting at /mnt/boot"
                mkfs.fat -F32 "${part}"
                mount --mkdir "${part}" /mnt/boot
                ;;
            *)
                echo "Unknown partition name: ${name}, skipping..."
                ;;
        esac
    done

    echo "All partitions formatted and mounted."
}

# =====================================
# Génération des noms de partitions
# =====================================
generate_parts() {
    local -n disks_ref="$1"
    local -n part_names_ref="$2"
    local -n part_disks_ref="$3"
    local -n out_parts_ref="$4"

    declare -A COUNTER
    local disk num part i

    echo "=== Generating partition device names ==="
    for disk in "${disks_ref[@]}"; do
        COUNTER["${disk}"]=1
    done

    for i in "${!part_names_ref[@]}"; do
        disk="${part_disks_ref[$i]}"
        num=${COUNTER["${disk}"]}

        if [[ "${disk}" =~ nvme ]]; then
            part="${disk}p${num}"
        else
            part="${disk}${num}"
        fi

        out_parts_ref+=("${part}")
        COUNTER["${disk}"]=$((num + 1))
        echo "Generated ${part} for partition '${part_names_ref[$i]}'"
    done
    echo "Partition names generation completed."
}