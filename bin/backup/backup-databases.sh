#!/bin/bash
# Versioniertes MySQL-Datenbank-Backup (externe Festplatte), zusätzlich Spiegelung in Nextcloud-Ordner
source /etc/profile

MOUNTPOINT="/media/chris/df87f35c-96a8-4369-9a9a-d3f32829b989"
DISK_UUID="df87f35c-96a8-4369-9a9a-d3f32829b989"

BACKUP_BASE="$MOUNTPOINT/backup-databases"
NEXTCLOUD_DIR="/home/chris/Nextcloud/9_Projekte/db-backups"

TS="$(date +"%Y-%m-%d_%H-%M")"

MYSQL_USER="admin"
MYSQL_PASS="Flock"

# Mountpoint anlegen
if [ ! -d "$MOUNTPOINT" ]; then
  echo "Einhängepunkt nicht vorhanden. Erstelle $MOUNTPOINT..."
  sudo mkdir -p "$MOUNTPOINT"
fi

# Mount prüfen
if ! mount | grep -q "$DISK_UUID"; then
  echo "Festplatte nicht gemountet. Versuche zu mounten..."
  sudo mount UUID=$DISK_UUID "$MOUNTPOINT" || {
    echo "❌ Fehler: Festplatte konnte nicht gemountet werden!"
    exit 1
  }
else
  echo "Festplatte ist bereits gemountet."
fi

# Zielverzeichnisse
RUN_DIR="$BACKUP_BASE/$TS"
mkdir -p "$RUN_DIR"
mkdir -p "$NEXTCLOUD_DIR"

echo "🗄️ Starte Datenbank-Backup nach: $RUN_DIR"

# DB-Liste (System-DBs raus)
databases=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" \
  | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")

# Backup je DB
for db in $databases; do
  echo "   🔁 Backing up $db ..."
  mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASS" --databases "$db" \
    > "$RUN_DIR/${db}.sql"
done

# Alte Backup-ORDNER löschen (älter als 30 Tage)
find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;

# In Nextcloud spiegeln (inkl. Löschungen)
rsync -a --delete "$BACKUP_BASE/" "$NEXTCLOUD_DIR/"

echo "✅ Datenbank-Backup abgeschlossen: $RUN_DIR und in Nextcloudordner gespiegelt"
