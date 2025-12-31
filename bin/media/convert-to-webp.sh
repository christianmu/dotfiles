#!/bin/bash
# ------------------------------------------------------------------
# 🔄 Konvertiert und verkleinert Bilder in WebP (mit Presets)
# ------------------------------------------------------------------

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
printf "${YELLOW}Konvertiert JPG, PNG und WebP in optimierte WebP-Dateien (rekursiv)${RESET}\n"
echo "------------------------------------------------------------------------------"
printf "+ Ausgabe im Unterverzeichnis ${YELLOW}/webp${RESET}, gleiche Ordnerstruktur.\n"
printf "+ Originale bleiben unverändert.\n"
printf "+ Unterstützte Presets: ${YELLOW}Foto${RESET} (Qualität 85 %%) oder ${YELLOW}Schrift${RESET} (Qualität 90 %%).\n"
echo

# Eingabe
read -rp "🎛️  Preset wählen (Foto=f/Schrift=s): " MODE
read -rp "📐 Maximale Kantenlänge in Pixel (z. B. 2560): " MAX_SIZE

# Preset-Einstellungen
case "$MODE" in
  f)
    QUALITY=85
    WEBP_ARGS=(-define webp:method=6 -define webp:auto-filter=true)
    ;;
  s)
    QUALITY=90
    WEBP_ARGS=(-define webp:method=6 -define webp:auto-filter=true -define webp:near-lossless=60)
    ;;
  *)
    echo "Ungültiges Preset. Bitte 'f' oder 's' eingeben."
    exit 1
    ;;
esac

INPUT_DIR="."
OUTPUT_DIR="webp"
converted=0
copied=0

# JPG/PNG-Dateien sammeln (webp-Ordner ausschließen)
mapfile -d '' image_files < <(find "$INPUT_DIR" -path "$OUTPUT_DIR" -prune -o \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -type f -print0)
total_images=${#image_files[@]}
progress=0

# Konvertieren
echo -e "\n🔄 Konvertiere JPG/PNG-Dateien:"
for img in "${image_files[@]}"; do
    rel_path=$(realpath --relative-to="$INPUT_DIR" "$img")
    [[ "$rel_path" == webp/* ]] && continue

    dir_path=$(dirname "$rel_path")
    file_base="${img##*/}"
    file_base="${file_base%.*}"
    out_dir="$OUTPUT_DIR/$dir_path"
    output="$out_dir/${file_base}.webp"

    mkdir -p "$out_dir"
    if magick "$img" -strip -resize "${MAX_SIZE}x${MAX_SIZE}\>" -filter Lanczos "${WEBP_ARGS[@]}" -quality "$QUALITY" "$output" &>/dev/null; then
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

# Vorhandene WebP-Dateien verarbeiten
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
        if magick "$img" -strip -resize "${MAX_SIZE}x${MAX_SIZE}\>" -filter Lanczos "${WEBP_ARGS[@]}" -quality "$QUALITY" "$output" &>/dev/null; then
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
echo
printf "📂 Ausgabeordner: ${YELLOW}%s${RESET}\n" "$OUTPUT_DIR"
echo
