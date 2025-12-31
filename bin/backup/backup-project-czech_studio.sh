#!/usr/bin/env bash
set -euo pipefail

# ============================
# Projekt-spezifische Angaben
# ============================

# QUELLE: Ordner, der gesichert werden soll
SRC="/var/www/html/wordpress/mu_czech_studio/"

# ZIEL-BASIS: Ordner in Nextcloud für dieses Projekt
DEST_BASE="/home/chris/Nextcloud/9_Projekte/Czech_Studio/mu_czech_studio-backups"

# ============================
# Ab hier nichts mehr ändern
# ============================

# Zeitstempel für dieses Backup
TS="$(date +%F_%H%M)"

# Zielordner für dieses Backup
DEST="$DEST_BASE/$TS"

# Lock, damit kein doppelter Lauf möglich ist
LOCK="/tmp/$(basename "$DEST_BASE").lock"

# Zielbasis anlegen (falls nicht vorhanden)
mkdir -p "$DEST_BASE"

# Backup ausführen
flock -n "$LOCK" rsync -a "$SRC" "$DEST"

# Kurze Erfolgsmeldung (nur bei manuellem Lauf sichtbar)
echo "Backup abgeschlossen: $DEST"

