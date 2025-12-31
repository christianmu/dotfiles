#!/bin/bash

# Interaktive Eingabe der URL und des Zielverzeichnisses
echo "Gib die URL der Webseite ein:"
read WEBSITE_URL
echo "Gib das Zielverzeichnis ein:"
read TARGET_DIR

# Verzeichnis erstellen, falls es nicht existiert
mkdir -p "$TARGET_DIR"

# Webseite mit wget herunterladen
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent --span-hosts --domains=$(echo $WEBSITE_URL | awk -F/ '{print $3}') \
     -e robots=off -P "$TARGET_DIR" "$WEBSITE_URL"

echo "Webseite wurde erfolgreich in '$TARGET_DIR' heruntergeladen!"
