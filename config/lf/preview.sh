#!/bin/sh

file=$1
width=$2
height=$3
mime=$(file --mime-type -Lb "$file")

BG_COLOR="242424"

case "$mime" in
    # --- IMAGES ---
    image/*)
        chafa -s "${width}x${height}" --format sixel --bg "${BG_COLOR}" --polite on -t 1 "$file"
        exit 1
        ;;

    # --- VIDEOS ---
    video/*)
        file_hash=$(echo "$file" | md5sum | cut -d' ' -f1)
        cache="/tmp/lf-thumb-${file_hash}.jpg"

        if [ ! -f "$cache" ]; then
            ffmpegthumbnailer -i "$file" -o "$cache" -s 0 -t 5 -q 10 -f 2>/dev/null
        fi

        chafa -s "${width}x${height}" --format sixel --bg "${BG_COLOR}" --polite on -t 1 "$cache"
        exit 1
        ;;

    # --- PDF ---
    application/pdf)
        # Utiliser un hash pour le PDF aussi évite les conflits si tu changes de fichier vite
        pdf_hash=$(echo "$file" | md5sum | cut -d' ' -f1)
        cache="/tmp/lf-pdf-${pdf_hash}.png"
        
        if [ ! -f "$cache" ]; then
            mutool draw -o "$cache" "$file" 1 >/dev/null 2>&1
        fi

        chafa -s "${width}x${height}" --format sixel --bg "${BG_COLOR}" --polite on -t 1 "$cache"
        exit 1
        ;;
        # --- AUDIO ---
    audio/*)
        echo "--- Audio Infos ---"
        ffprobe -hide_banner -i "$file" 2>&1 | grep -E "Duration|Stream"
        ;;

    # --- ARCHIVES (La liste complète pour ouch) ---
    application/zip|application/x-tar|application/x-gzip|application/x-7z-compressed|application/vnd.rar|application/x-rar|application/x-bzip2|application/x-xz|application/x-zstd|application/x-lz4)
        echo "--- Archive's Content (ouch) ---"
        echo ""
        ouch list "$file" | head -n 30
        ;;

    # --- TEXTE & CODE (bat gère tout ça) ---
    text/*|application/json|application/xml|application/javascript|application/x-sh)
        bat --color=always --style=plain "$file"
        ;;

    # --- PAR DÉFAUT ---
    *)
        echo "Format: $mime"
        file -b "$file"
        ;;  
esac