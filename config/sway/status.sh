#!/bin/bash

while true; do
    date_time=$(date +'%d/%m/%Y %H:%M')
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    mem_info=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')

    if systemctl is-active --quiet iwd; then
        wifi_status=on
    else
        wifi_status=off
    fi

    all_disks=""
    # On liste les disques physiques (sda, nvme0n1...)
    for dev in $(lsblk -dnlo NAME | grep -v "loop"); do
        
        # On cherche la ligne dans 'df' qui correspond à ce disque (/dev/sda1, /dev/sda2...)
        # On prend la partition la plus utilisée (souvent la principale)
        usage=$(df -h | grep "/dev/$dev" | awk '{print $5}' | sort -rn | head -n1)

        if [ -n "$usage" ]; then
            # Détection SSD ou HDD
            is_rotational=$(cat /sys/block/"$dev"/queue/rotational 2>/dev/null)
            [ "$is_rotational" == "0" ] && label="SSD" || label="HDD"
            
            all_disks="$all_disks | $label: $usage"
        fi
    done

    echo "WIFI: $wifi_status | CPU: $cpu_usage% | RAM: $mem_info$all_disks | $date_time"

    sleep 5
done