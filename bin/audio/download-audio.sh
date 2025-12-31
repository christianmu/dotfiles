#!/usr/bin/env bash

echo "🔗 Bitte gib den YouTube-Link ein:"
read LINK

if [ -z "$LINK" ]; then
    echo "❌ Kein Link eingegeben. Abbruch."
    exit 1
fi

echo "💾 Wie soll die Ausgabedatei heißen? (ohne .mp3)"
read NAME

if [ -z "$NAME" ]; then
    echo "⚠️ Kein Name eingegeben – verwende Standardnamen: audio"
    NAME="audio"
fi

echo "🎧 Lade Audio herunter..."
yt-dlp --no-playlist -x --audio-format mp3 -o "${NAME}.%(ext)s" "$LINK"

echo "✅ Fertig! Datei gespeichert als: ${NAME}.mp3"

