#!/usr/bin/env bash
set -euo pipefail

echo "🔗 Bitte gib den YouTube-Link ein:"
read -r LINK

if [ -z "$LINK" ]; then
    echo "❌ Kein Link eingegeben. Abbruch."
    exit 1
fi

echo "💾 Wie soll die Ausgabedatei heißen? (ohne Endung, z.B. 18-2-audio)"
read -r BASENAME

if [ -z "$BASENAME" ]; then
    echo "⚠️ Kein Name eingegeben – verwende Standardnamen: audio"
    BASENAME="audio"
fi

# 1) Prüfen, ob benötigte Programme vorhanden sind
for cmd in yt-dlp ffmpeg whisper; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Fehler: '$cmd' ist nicht installiert oder nicht im PATH."
        exit 1
    fi
done

echo "🎧 Lade bestes Audio mit yt-dlp herunter …"
yt-dlp \
    --no-playlist \
    -f bestaudio \
    -o "${BASENAME}.%(ext)s" \
    "$LINK"

# 2) Tatsächlich heruntergeladene Datei ermitteln (kann .m4a/.webm/etc. sein)
DOWNLOAD_FILE=$(ls "${BASENAME}."* 2>/dev/null | head -n 1 || true)
if [ -z "$DOWNLOAD_FILE" ]; then
    echo "❌ Konnte die heruntergeladene Datei nicht finden."
    exit 1
fi

echo "📁 Heruntergeladen als: ${DOWNLOAD_FILE}"

# 3) Audio normalisieren
NORM_WAV="${BASENAME}_norm.wav"
echo "🎚 Normalisiere Audio mit ffmpeg loudnorm → ${NORM_WAV} …"
ffmpeg -y -i "$DOWNLOAD_FILE" -af loudnorm "$NORM_WAV"

# 4) Whisper-Transkription
echo "📝 Transkribiere mit Whisper (model: medium, device: cpu, language: cs) …"
whisper "$NORM_WAV" \
    --language cs \
    --task transcribe \
    --model medium \
    --device cpu \
    --output_format all

SRT_FILE="${BASENAME}_norm.srt"
TXT_FILE="${BASENAME}_norm.txt"

echo "✅ Fertig!"
[ -f "$SRT_FILE" ] && echo "   📄 Untertitel:   $SRT_FILE"
[ -f "$TXT_FILE" ] && echo "   📜 Transkript:   $TXT_FILE"
echo "   💽 Normalisiertes Audio: $NORM_WAV"
echo "   🔊 Original-Download:    $DOWNLOAD_FILE"

echo
echo "ℹ️ Tipp: ${SRT_FILE} kannst du direkt in Totem/VLC laden."
echo "   ${TXT_FILE} ist ideal als Basis für deine Kurs-Texte in Czech Studio."
