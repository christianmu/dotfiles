#!/bin/bash
source /etc/profile

# Ziel-Mountpoint und UUID der Festplatte
MOUNTPOINT="/media/chris/df87f35c-96a8-4369-9a9a-d3f32829b989"
DISK_UUID="df87f35c-96a8-4369-9a9a-d3f32829b989"
DATE=$(date +%Y-%m-%d_%H:%M)

# Prüfen, ob der Mountpoint existiert, und bei Bedarf erstellen
if [ ! -d "$MOUNTPOINT" ]; then
    echo "Einhängepunkt nicht vorhanden. Erstelle $MOUNTPOINT..."
    sudo mkdir -p "$MOUNTPOINT"
fi

# Prüfen, ob die Festplatte bereits gemountet ist
if ! mount | grep -q "$MOUNTPOINT"; then
    echo "Festplatte nicht gemountet. Versuche zu mounten..."
    sudo mount UUID=$DISK_UUID "$MOUNTPOINT"
    if [ $? -ne 0 ]; then
        echo "❌ Fehler: Festplatte konnte nicht gemountet werden!"
        exit 1
    fi
fi

# Sicherstellen, dass das Zielverzeichnis existiert
BACKUP_DIR="$MOUNTPOINT/backup-codeordner_$DATE"
mkdir -p "$BACKUP_DIR"

# Backup mit rsync durchführen
echo "🔁 Starte Backup des Code-Ordners (/home/chris/Code) …"
rsync -av /home/chris/Code/ "$BACKUP_DIR"

echo "✅ Backup abgeschlossen: $BACKUP_DIR"
