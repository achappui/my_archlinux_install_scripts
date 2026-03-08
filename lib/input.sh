#!/bin/bash
set -euo pipefail

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

ask_profile() {
    VAR_NAME=$1
    PROFILES=($(ls profiles/*.sh | xargs -n1 basename | sed 's/\.sh$//'))

    echo "Available profiles:"
    for i in "${!PROFILES[@]}"; do
        printf "%d) %s\n" "$((i+1))" "${PROFILES[$i]}"
    done

    while true; do
        read -p "Enter choice (1-${#PROFILES[@]}): " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#PROFILES[@]} )); then
            eval "$VAR_NAME='${PROFILES[$((CHOICE-1))]}'"
            break
        else
            echo "Invalid choice. Try again."
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