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

    for disk in "${disks[@]}"; do
        if [ "${auto_confirm}" != "true" ]; then
            echo "Type YES to wipe ${disk}"
            read CONFIRM
            if [[ "${CONFIRM}" != "YES" ]]; then
                echo "Cancelled."
                exit 1
            fi
        fi
        sgdisk --zap-all "${disk}"
    done
}

create_partitions() {
    local -n names_ref="$1"
    local -n disks_ref="$2"
    local -n sizes_ref="$3"
    local -n types_ref="$4"
    local i

    for i in "${!parts_ref[@]}"; do
        sgdisk -n 0:0:${sizes_ref[$i]} -t 0:${types_ref[$i]} -c 0:"${names_ref[$i]}" "${disks_ref[$i]}"
    done
}

format_and_mount() {
    local -n parts_ref="$1"
    local -n names_ref="$2"
    local i
    local part
    local name

    for i in "${!parts_ref[@]}"; do
        part="${parts_ref[$i]}"
        name="${names_ref[$i]}"

        case "${name}" in
            EFI)
                mkfs.fat -F32 "${part}"
                mount --mkdir "${part}" /mnt/boot
                ;;
            swap)
                mkswap -f "${part}"
                swapon "${part}"
                ;;
            root)
                mkfs.ext4 -F "${part}"
                mount "${part}" /mnt
                ;;
            home)
                mkfs.ext4 -F "${part}"
                mount --mkdir "${part}" /mnt/home
                ;;
        esac
    done
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
    done
}