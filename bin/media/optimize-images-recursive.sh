#!/bin/bash

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Fortschrittsbalken
progress_bar() {
    local progress=$1
    local total=$2
    local width=50
    local percent=$(( 100 * progress / total ))
    local filled=$(( width * progress / total ))
    local empty=$(( width - filled ))
    local bar=$(printf "%0.s█" $(seq 1 $filled))
    local space=$(printf "%0.s " $(seq 1 $empty))
    printf "\r[%s%s] %3d%% (%d/%d)" "$bar" "$space" "$percent" "$progress" "$total"
}

# Begrüßung
echo
printf "${YELLOW}Komprimiert und verkleinert Bilder aller Unterordner im aktuellen Verzeichnis${RESET}\n"
echo "-----------------------------------------------------------------------------"
printf "+ Das Skript ist portabel und wird im jeweils ${YELLOW}aktuellen${RESET} Verzeichnis ausgeführt.\n"
printf "+ Die Ausgabe erfolgt im Unterverzeichnis ${YELLOW}/webp${RESET}, mit gleicher Ordnerstruktur.\n"
printf "+ Umgewandelt werden .jpg-, .jpeg- und .png-Dateien (.webp-Dateien werden nur verkleinert und kopiert).\n"
printf "+ Ausgabeformat ist .webp.\n"
echo

# Eingabe
read -rp "🔧 Bildqualität in Prozent (z.B. 82): " QUALITY
read -rp "📐 Maximale Kantenlänge in Pixel (z.B. 1200): " MAX_SIZE

INPUT_DIR="."
OUTPUT_DIR="webp"

converted=0
copied=0

# JPG/PNG-Dateien sammeln (webp-Ordner ausschließen)
mapfile -d '' image_files < <(find "$INPUT_DIR" -path "$OUTPUT_DIR" -prune -o \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -type f -print0)
total_images=${#image_files[@]}
progress=0

# Konvertieren
echo -e "\n🔄 Konvertiere Bilder:"
for img in "${image_files[@]}"; do
    rel_path=$(realpath --relative-to="$INPUT_DIR" "$img")
    [[ "$rel_path" == webp/* ]] && continue

    dir_path=$(dirname "$rel_path")
    base_name=$(basename "$img")
    file_base="${base_name%.*}"
    out_dir="$OUTPUT_DIR/$dir_path"
    output="$out_dir/${file_base}.webp"

    mkdir -p "$out_dir"
    if magick "$img" -resize "${MAX_SIZE}x${MAX_SIZE}\>" -quality "$QUALITY" "$output" &>/dev/null; then
        ((converted++))
    fi

    ((progress++))
    progress_bar "$progress" "$total_images"
done
echo

# WebP-Dateien sammeln (webp-Ordner ausschließen)
mapfile -d '' webp_files < <(find "$INPUT_DIR" -path "$OUTPUT_DIR" -prune -o -iname "*.webp" -type f -print0)
total_webps=${#webp_files[@]}
progress=0

# WebP-Verarbeitung
echo -e "\n📦 Verarbeite vorhandene WebP-Dateien:"
for img in "${webp_files[@]}"; do
    rel_path=$(realpath --relative-to="$INPUT_DIR" "$img")
    [[ "$rel_path" == webp/* ]] && continue

    dir_path=$(dirname "$rel_path")
    out_dir="$OUTPUT_DIR/$dir_path"
    output="$out_dir/$(basename "$img")"

    mkdir -p "$out_dir"
    read width height < <(identify -format "%w %h" "$img")

    if (( width > MAX_SIZE || height > MAX_SIZE )); then
        if magick "$img" -resize "${MAX_SIZE}x${MAX_SIZE}\>" "$output" &>/dev/null; then
            ((converted++))
        fi
    else
        if cp "$img" "$output"; then
            ((copied++))
        fi
    fi

    ((progress++))
    progress_bar "$progress" "$total_webps"
done
echo

# Zusammenfassung
echo
printf "${GREEN}✅ %d Bild(er) konvertiert, %d WebP(s) kopiert (unverändert).${RESET}\n" "$converted" "$copied"
