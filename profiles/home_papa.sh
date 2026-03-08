#!/usr/bin/env bash
set -euo pipefail

D=("/dev/nvme0n1")

PART_NAMES=(    "EFI"       "swap"      "root"      )
PART_SIZES=(    "+1G"       "+8G"       "0"         )
PART_TYPES=(    "ef00"      "8200"      "8300"      )
PART_DISK=(     "${D[0]}"   "${D[0]}"   "${D[0]}"   )
