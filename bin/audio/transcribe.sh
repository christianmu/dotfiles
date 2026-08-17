#!/usr/bin/env bash

set -e  # Bei Fehlern abbrechen

echo "🔗 Bitte gib den Link ein:"
read -r LINK

if [ -z "$LINK" ]; then
    echo "❌ Kein Link eingegeben. Abbruch."
    exit 1
fi

echo "💾 Wie soll die Ausgabedatei heißen? (ohne Endung)"
read -r NAME

if [ -z "$NAME" ]; then
    echo "⚠️ Kein Name eingegeben – verwende den Standardnamen: audio"
    NAME="audio"
fi

AUDIO_FILE="${NAME}.webm"

echo
echo "🎧 Erstelle Audiodatei aus der Quelle …"
ffmpeg -y -i "$LINK" -vn -c:a libopus "$AUDIO_FILE"

if [ ! -f "$AUDIO_FILE" ]; then
    echo "❌ Fehler: Die Audiodatei wurde nicht erstellt: $AUDIO_FILE"
    exit 1
fi

echo
echo "📝 Starte Whisper-Transkription …"
echo "   → Datei   : $AUDIO_FILE"
echo "   → Sprache : cs"
echo "   → Modell  : large"
echo "   → Gerät   : cuda"
echo

whisper "$AUDIO_FILE" \
  --language cs \
  --task transcribe \
  --model large \
  --device cuda \
  --output_format all

echo
echo "✅ Fertig!"
echo "   🎧 Audio-Datei : $AUDIO_FILE"
echo "   📝 Whisper-Ausgaben:"
echo "      - ${NAME}.txt"
echo "      - ${NAME}.srt"
echo "      - ${NAME}.json"
echo "      - ${NAME}.vtt"
echo "      - ${NAME}.tsv"

