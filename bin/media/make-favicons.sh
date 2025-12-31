#!/usr/bin/env bash
set -euo pipefail

# Usage: ./make-favicons.sh path/to/logo.svg [output-dir] [base-name]
# - base-name (optional): Basis für Dateinamen (ohne Extension). Wenn weggelassen, wird interaktiv gefragt.

# Farben definieren
YELLOW='\033[0;33m'
RESET='\033[0m'

# Begrüßungsnachricht
echo
printf '%b\n' "${YELLOW}Erstellt PNGs aus einem SVG${RESET}"
echo "------------------------------------"
printf '%b\n' "+ Pflichteingabe: umzuwandelndendes SVG."
printf '%b\n' "+ Optional: Pfad zum Ausgabeordner (Standard: favicons)."
printf '%b\n' "+ Optional: gewünschten Dateinamen ohne Dateiendung (Standard: icon)."
echo

IN="${1:-}"
OUT="${2:-favicons}"
BASE_INPUT="${3:-}"

if [[ -z "$IN" || ! -f "$IN" ]]; then
  echo "Usage: $0 path/to/logo.svg [output-dir] [base-name]"
  exit 1
fi

mkdir -p "$OUT"

# ---- helper: slugify to kebab-case (a-z, 0-9, dot), collapse dashes ----
slugify () {
  tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9.]+/-/g; s/-+/-/g; s/^-//; s/-$//'
}

# ---- ask for base name if not provided ----
BASE_DEFAULT="icon"
if [[ -z "$BASE_INPUT" ]]; then
  read -rp "Dateiname (ohne Dateiendung) [${BASE_DEFAULT}]: " BASE_INPUT
fi
BASE_INPUT="${BASE_INPUT:-$BASE_DEFAULT}"
BASE="$(printf '%s' "$BASE_INPUT" | slugify)"

# ---- helper: export PNG from SVG (prefers inkscape) ----
export_png () {
  local size="$1" ; local out="$2"
  if command -v inkscape >/dev/null 2>&1; then
    inkscape "$IN" --export-type=png --export-filename="$out" --export-width="$size" --export-height="$size" >/dev/null
  elif command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$size" -h "$size" "$IN" -o "$out"
  else
    echo "Need inkscape or rsvg-convert. Install with: sudo apt install inkscape || sudo apt install librsvg2-bin"
    exit 1
  fi
}

# ---- sizes ----
export_png 32  "$OUT/${BASE}-32.png"
export_png 48  "$OUT/${BASE}-48.png"
export_png 180 "$OUT/${BASE}-180.png"   # Apple touch icon
export_png 192 "$OUT/${BASE}-192.png"   # Android/manifest
export_png 256 "$OUT/${BASE}-256.png"
export_png 512 "$OUT/${BASE}-512.png"   # PWA / high-res

# optional: kopiere das SVG selbst (moderne Browser können es als Favicon nutzen)
cp "$IN" "$OUT/${BASE}.svg"

# ---- build favicon.ico (16 + 32) ----
# Wenn kein 16er vorhanden, aus 32er herunterskalieren
if command -v magick >/dev/null 2>&1; then
  magick "$OUT/${BASE}-32.png" -resize 16x16 "$OUT/.tmp-16.png"
  magick "$OUT/.tmp-16.png" "$OUT/${BASE}-32.png" "$OUT/favicon.ico"
  rm -f "$OUT/.tmp-16.png"
elif command -v convert >/dev/null 2>&1; then
  convert "$OUT/${BASE}-32.png" -resize 16x16 "$OUT/.tmp-16.png"
  convert "$OUT/.tmp-16.png" "$OUT/${BASE}-32.png" "$OUT/favicon.ico"
  rm -f "$OUT/.tmp-16.png"
else
  echo "ImageMagick not found; skipping favicon.ico. Install: sudo apt install imagemagick"
fi
# ---- minimal site.webmanifest ----
cat > "$OUT/site.webmanifest" <<JSON
{
  "name": "${BASE^}",
  "short_name": "${BASE^}",
  "description": "Web App created with ${BASE^}.",
  "icons": [
    { "src": "${BASE}-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "${BASE}-512.png", "sizes": "512x512", "type": "image/png" }
  ],
  "theme_color": "#2a2a2a",
  "background_color": "#ffffff",
  "display": "standalone",
  "start_url": "."
}
JSON

# ---- optional optimization (if tools exist) ----
if command -v optipng >/dev/null 2>&1; then
  optipng -quiet -o7 "$OUT"/*.png || true
fi
if command -v pngquant >/dev/null 2>&1; then
  pngquant --skip-if-larger --force --ext .png "$OUT"/*.png || true
fi

echo "Done. Files in: $OUT"
ls -1 "$OUT"
