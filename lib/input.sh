#!/bin/bash
set -euo pipefail

ask_input() {
    local PROMPT="$1"
    local VAR_NAME="$2"
    local VALUE

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

ask_profile() {
    local PROMPT="$1"
    local VAR_NAME="$2"
    local BASENAMES=()
    local f
    local i
    local CHOICE

    for f in ../profiles/*.sh; do
        BASENAMES+=("$(basename "$f" .sh)")
    done

    echo "${PROMPT}:"
    for i in "${!BASENAMES[@]}"; do
        printf "%d) %s\n" "$((i+1))" "${BASENAMES[$i]}"
    done

    while true; do
        read -p "Enter choice (1-${#BASENAMES[@]}): " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#BASENAMES[@]} )); then
            eval "${VAR_NAME}='${BASENAMES[$((CHOICE-1))]}'"
            break
        else
            echo "Invalid choice. Try again."
        fi
    done
}

ask_boolean() {
    local PROMPT="$1"
    local VAR_NAME="$2"
    local VALUE

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