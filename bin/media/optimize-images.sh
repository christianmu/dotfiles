#!/bin/bash

# 📥 Interaktive Parameter
read -rp "🔧 Bildqualität (z. B. 82): " QUALITY
read -rp "📐 Maximale Kantenlänge in Pixel (z. B. 1200): " MAX_SIZE

# 📁 Ordner setzen
INPUT_DIR="."
OUTPUT_DIR="webp"

mkdir -p "$OUTPUT_DIR"

# ⚙️ Optionen aktivieren
shopt -s nullglob nocaseglob
converted=0
copied=0

# 🔄 Konvertierung: JPG, JPEG, PNG → WebP
for img in "$INPUT_DIR"/*.{jpg,jpeg,png}; do
    [ -e "$img" ] || continue
    filename=$(basename "$img")
    base="${filename%.*}"
    output="${OUTPUT_DIR}/${base}.webp"

    echo "🖼️  Konvertiere: $filename → $output"
    magick "$img" -resize "${MAX_SIZE}x${MAX_SIZE}\>" -quality "$QUALITY" "$output" && ((converted++))
done

# 🔄 Behandlung vorhandener WebP-Dateien
for img in "$INPUT_DIR"/*.webp; do
    [ -e "$img" ] || continue
    filename=$(basename "$img")
    output="${OUTPUT_DIR}/${filename}"

    # Aktuelle Bildgröße ermitteln
    read width height <<< "$(identify -format "%w %h" "$img")"

    if (( width > MAX_SIZE || height > MAX_SIZE )); then
        echo "📏  Skaliere vorhandenes WebP: $filename → $output"
        magick "$img" -resize "${MAX_SIZE}x${MAX_SIZE}\>" "$output" && ((converted++))
    else
        echo "📎  Kopiere unverändertes WebP: $filename"
        cp "$img" "$output" && ((copied++))
    fi
done

shopt -u nullglob nocaseglob

# ✅ Zusammenfassung
echo "✅ $converted Bild(er) konvertiert, $copied WebP(s) kopiert (unverändert)."


