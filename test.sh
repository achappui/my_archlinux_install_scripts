#!/bin/sh

# --- 1️⃣ Stockage des choix ---
MY_HOSTNAME=""
MY_ROOT_PASSWORD=""
MY_USER=""
MY_USER_PASSWORD=""
MY_IS_IMAC="false"
MY_DRIVER=""
DISK_CHOICE=""
EFI_SIZE=""
ROOT_SIZE=""
USER_SIZE=""

# --- Fonctions ---
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

# --- 3️⃣ Partition / Disk ---
# On suppose qu'on a déjà clear les disques si nécessaire
while true; do
    printf "Enter disk name for partitioning: "
    read DISK_CHOICE
    if [ -n "${DISK_CHOICE}" ]; then
        printf "EFI partition size (e.g., 512M, all): "
        read EFI_SIZE
        printf "Root partition size (e.g., 20G, all): "
        read ROOT_SIZE
        printf "User partition size (e.g., rest of disk): "
        read USER_SIZE
        break
    else
        echo "Disk name cannot be empty."
    fi
done

# --- 4️⃣ Récapitulatif et confirmation ---
while true; do
    echo "=== Summary ==="
    echo "Hostname: ${MY_HOSTNAME}"
    echo "Root password: ******"
    echo "User: ${MY_USER}"
    echo "User password: ******"
    echo "Is iMac: ${MY_IS_IMAC}"
    echo "GPU driver: ${MY_DRIVER}"
    echo "Disk: ${DISK_CHOICE}"
    echo "EFI size: ${EFI_SIZE}"
    echo "Root size: ${ROOT_SIZE}"
    echo "User size: ${USER_SIZE}"
    printf "Confirm? [y/n]: "
    read CONFIRM
    case "${CONFIRM}" in
        y|Y)
            echo "Configuration confirmed."
            break
            ;;
        n|N)
            echo "Restarting input..."
            # Ici on peut rappeler les fonctions pour refaire les inputs si nécessaire
            # Pour simplifier, on redemande juste les partitions et booleans
            ask_boolean "Is this an iMac?" MY_IS_IMAC
            ask_choice "Choose GPU driver" MY_DRIVER "nvidia_maxwell_to_volta" "intel_iris_pro_graphics"
            while true; do
                printf "Enter disk name for partitioning: "
                read DISK_CHOICE
                if [ -n "${DISK_CHOICE}" ]; then
                    printf "EFI partition size (e.g., 512M, all): "
                    read EFI_SIZE
                    printf "Root partition size (e.g., 20G, all): "
                    read ROOT_SIZE
                    printf "User partition size (e.g., rest of disk): "
                    read USER_SIZE
                    break
                else
                    echo "Disk name cannot be empty."
                fi
            done
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done