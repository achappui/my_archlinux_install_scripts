#!/bin/sh

file=$1
width=$2
height=$3
mime=$(file --mime-type -Lb "$file")

case "$mime" in
    # --- IMAGES ---
    image/*)
        chafa -s "${width}x${height}" --format sixel "$file"
        exit 1
        ;;

    # --- VIDEOS ---
    video/*)
        cache="/tmp/lf-vid.jpg"
        ffmpegthumbnailer -i "$file" -o "$cache" -s 0
        chafa -s "${width}x${height}" --format sixel "$cache"
        exit 1
        ;;

    # --- PDF ---
    application/pdf)
        cache="/tmp/lf-pdf.png"
        # mutool appartient au paquet mupdf-tools
        mutool draw -o "$cache" "$file" 1 >/dev/null
        chafa -s "${width}x${height}" --format sixel "$cache"
        exit 1
        ;;

    # --- AUDIO ---
    audio/*)
        echo "--- Infos Audio ---"
        ffprobe -hide_banner -i "$file" 2>&1 | grep -E "Duration|Stream"
        ;;

    # --- ARCHIVES (La liste complète pour ouch) ---
    application/zip|application/x-tar|application/x-gzip|application/x-7z-compressed|application/vnd.rar|application/x-rar|application/x-bzip2|application/x-xz|application/x-zstd|application/x-lz4)
        echo "--- Contenu de l'archive (ouch) ---"
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