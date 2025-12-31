#!/usr/bin/env bash

set -e  # Bei Fehlern abbrechen

echo "🔗 Bitte gib den YouTube-Link ein:"
read -r LINK

if [ -z "$LINK" ]; then
    echo "❌ Kein Link eingegeben. Abbruch."
    exit 1
fi

echo "💾 Wie soll die Ausgabedatei heißen? (ohne Endung)"
read -r NAME

if [ -z "$NAME" ]; then
    echo "⚠️ Kein Name eingegeben – verwende Standardnamen: audio"
    NAME="audio"
fi

AUDIO_FILE="${NAME}.webm"

echo
echo "🎧 Lade Audio als Original-WebM (Opus) herunter …"
yt-dlp \
  --no-playlist \
  -f bestaudio \
  -o "${NAME}.%(ext)s" \
  "$LINK"

if [ ! -f "$AUDIO_FILE" ]; then
    echo "❌ Fehler: Die Audiodatei wurde nicht gefunden: $AUDIO_FILE"
    exit 1
fi

echo
echo "📝 Starte Whisper-Transkription …"
echo "   → Datei   : $AUDIO_FILE"
echo "   → Sprache : cs"
echo "   → Modell  : medium"
echo "   → Gerät   : cpu"
echo

whisper "$AUDIO_FILE" \
  --language cs \
  --task transcribe \
  --model medium \
  --device cpu

echo
echo "✅ Fertig!"
echo "   🎧 Audio-Datei : $AUDIO_FILE"
echo "   📝 Whisper-Ausgaben:"
echo "      - ${NAME}.txt"
echo "      - ${NAME}.srt"
echo "      - ${NAME}.json"
echo "      - ${NAME}.vtt"
echo "      - ${NAME}.tsv"

