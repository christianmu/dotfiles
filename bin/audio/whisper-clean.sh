#!/usr/bin/env bash

# =====================================
# Whisper JSON → Lern-JSON Konverter
# Entfernt Ballast + legt "de"-Feld an
# =====================================

INPUT="$1"

if [ -z "$INPUT" ]; then
  echo "❌ Bitte JSON-Datei angeben."
  echo "Beispiel: ./whisper-clean-learn.sh lesson26.json"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "❌ Datei nicht gefunden: $INPUT"
  exit 1
fi

OUTPUT="${INPUT%.json}.learn.json"

jq '{
  segments: [
    .segments[] |
    {
      start: .start,
      end: .end,
      text: (.text | ltrimstr(" ") | rtrimstr(" ")),
      de: ""
    }
  ]
}' "$INPUT" > "$OUTPUT"

echo "✅ Lern-JSON erstellt:"
echo "   $OUTPUT"

