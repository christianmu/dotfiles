#!/bin/bash
source /etc/profile

# Ziel-Mountpoint und UUID der Festplatte
MOUNTPOINT="/media/chris/df87f35c-96a8-4369-9a9a-d3f32829b989"
DISK_UUID="df87f35c-96a8-4369-9a9a-d3f32829b989"

# Sicherstellen, dass der Mountpoint existiert
if [ ! -d "$MOUNTPOINT" ]; then
    echo "Einhängepunkt nicht vorhanden. Erstelle $MOUNTPOINT..."
    sudo mkdir -p "$MOUNTPOINT"
fi

# Prüfen, ob die Festplatte bereits gemountet ist
if ! mount | grep -q "$MOUNTPOINT"; then
    echo "Festplatte nicht gemountet. Versuche zu mounten..."
    sudo mount UUID=$DISK_UUID $MOUNTPOINT
    if [ $? -ne 0 ]; then
        echo "❌ Fehler: Festplatte konnte nicht gemountet werden!"
        exit 1
    fi
fi

# Neuen Backup-Ordner für ~/bin erzeugen
BACKUP_DIR="$MOUNTPOINT/backup-bin_$(date +%Y-%m-%d_%H:%M)"
mkdir -p "$BACKUP_DIR"

# Backup mit rsync durchführen
rsync -av /home/chris/bin/ "$BACKUP_DIR"

echo "✅ Backup abgeschlossen: $BACKUP_DIR"
