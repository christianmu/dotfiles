#!/bin/bash

echo "🔧 Croppen aller .webp-Dateien im aktuellen Ordner → 16:9"

shopt -s nullglob
files=( *.webp )

if [ ${#files[@]} -eq 0 ]; then
    echo "❌ Keine .webp-Dateien gefunden."
    exit 1
fi

echo
echo "⚠️  Folgende Dateien werden ÜBERSCHRIEBEN:"
printf " - %s\n" "${files[@]}"
echo

read -p "👉 Wirklich fortfahren? (j/N): " confirm
if [[ "$confirm" != "j" ]]; then
    echo "❎ Abgebrochen. Es wurde nichts verändert."
    exit 0
fi

echo

for f in "${files[@]}"; do
    echo "✂️  Bearbeite: $f"
    ffmpeg -i "$f" \
        -vf "crop=in_w:in_w*9/16:0:(in_h - in_w*9/16)/2" \
        ".__tmp__$f" -y && mv ".__tmp__$f" "$f"
done

echo
echo "✅ Fertig! Nur der aktuelle Ordner wurde sicher bearbeitet."
