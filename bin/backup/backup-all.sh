#!/bin/bash
source /etc/profile

# Allgemeine Variablen
MOUNTPOINT="/media/chris/df87f35c-96a8-4369-9a9a-d3f32829b989"
DISK_UUID="df87f35c-96a8-4369-9a9a-d3f32829b989"
DATE=$(date +"%Y-%m-%d_%H:%M")
MYSQL_USER="admin"
MYSQL_PASS="Flock"

# Prüfen, ob der Mountpoint existiert, und bei Bedarf erstellen
if [ ! -d "$MOUNTPOINT" ]; then
    echo "Einhängepunkt nicht vorhanden. Erstelle $MOUNTPOINT..."
    sudo mkdir -p "$MOUNTPOINT"
fi

# Prüfen, ob die Festplatte bereits gemountet ist
if ! mount | grep -q "$DISK_UUID"; then
    echo "Festplatte nicht gemountet. Versuche zu mounten..."
    sudo mount UUID=$DISK_UUID $MOUNTPOINT
    if [ $? -ne 0 ]; then
        echo "Fehler: Festplatte konnte nicht gemountet werden!"
        exit 1
    fi
else
    echo "Festplatte ist bereits gemountet."
fi

# --- Datenbank-Backup ---
echo "Starte Datenbank-Backup..."
BACKUP_DIR_DB="$MOUNTPOINT/backup-databases"
mkdir -p "$BACKUP_DIR_DB"

databases=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")
for db in $databases; do
    echo "Backing up $db"
    mysqldump -u$MYSQL_USER -p$MYSQL_PASS --databases $db > "$BACKUP_DIR_DB/${db}_$DATE.sql"
done
find "$BACKUP_DIR_DB" -type f -mtime +30 -exec rm {} \;
echo "Datenbank-Backup abgeschlossen: $BACKUP_DIR_DB"

# --- Code-Ordner-Backup ---
echo "Starte Backup des Code-Ordners..."
BACKUP_DIR_CODE="$MOUNTPOINT/backup-code_$DATE"
mkdir -p "$BACKUP_DIR_CODE"
rsync -av /home/chris/Code "$BACKUP_DIR_CODE"
echo "Code-Ordner-Backup abgeschlossen: $BACKUP_DIR_CODE"

# --- Nextcloud-Ordner-Backup ---
echo "Starte Backup des Nextcloud-Ordners..."
BACKUP_DIR_NEXTCLOUD="$MOUNTPOINT/backup-nextcloud_$DATE"
mkdir -p "$BACKUP_DIR_NEXTCLOUD"
rsync -av /home/chris/Nextcloud "$BACKUP_DIR_NEXTCLOUD"
echo "Nextcloud-Ordner-Backup abgeschlossen: $BACKUP_DIR_NEXTCLOUD"

# --- Scripts-Ordner-Backup (neu: ~/bin) ---
echo "Starte Backup des Scripts-Ordners (~/bin)..."
BACKUP_DIR_SCRIPTS="$MOUNTPOINT/backup-bin_$DATE"
mkdir -p "$BACKUP_DIR_SCRIPTS"
rsync -av /home/chris/bin/ "$BACKUP_DIR_SCRIPTS"
echo "Scripts-Ordner-Backup abgeschlossen: $BACKUP_DIR_SCRIPTS"

# --- WWW-Ordner-Backup ---
echo "Starte Backup des WWW-Ordners..."
BACKUP_DIR_WWW="$MOUNTPOINT/backup-www_$DATE"
mkdir -p "$BACKUP_DIR_WWW"
rsync -av /var/www/ "$BACKUP_DIR_WWW"
echo "WWW-Ordner-Backup abgeschlossen: $BACKUP_DIR_WWW"

echo "Alle Backups erfolgreich abgeschlossen!"
