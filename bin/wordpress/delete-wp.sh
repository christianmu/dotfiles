#!/bin/sh

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${RED}Löschung einer WordPress-Seite${RESET}\n"
echo "------------------------------"
printf "Entfernt im Arbeitsverzeichnis vorhandene WordPress-Installationen samt zugehörigen Datenbanken.\n"
printf "V-Host-Registrierungen ${YELLOW}/etc/hosts${RESET}, Konfigurationen ${YELLOW}/etc/apache2/sites-available/${RESET} und TLS-Zertifikate ${YELLOW}/etc/ssl/certs/${RESET} bleiben unberührt.\n"
echo

# Datenbankinformationen
echo "Name der zu löschenden WordPress-Instanz:"	# Interaktive Abfrage für die zu löschende Datenbank (löscht auch das gleichnamige Verzeichnis)
read DB_NAME
DB_USER="admin"
DB_PASS="Flock"
DB_HOST="localhost"

# Aktuelles Verzeichnis als Basis verwenden
BASE_DIR=$(pwd)

# Installationsverzeichnis von WordPress
WP_PATH="$BASE_DIR/$DB_NAME"

# Prüfen, ob das Installationsverzeichnis existiert
if [ ! -d "$WP_PATH" ]; then
    printf "${RED}❌ Fehler:${RESET} Das Installationsverzeichnis '$WP_PATH' existiert nicht.\n"
    exit 1
fi

# Bestätigungsnachricht vor der Löschung
echo "Bist du sicher, dass du die WordPress-Installation und die Datenbank '$DB_NAME' löschen möchtest? [ja/Nein] "
read confirmation

# Entfernen von führenden und nachfolgenden Leerzeichen und Konvertierung in Kleinbuchstaben
confirmation=$(echo "$confirmation" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# Leere Eingabe oder alles außer "y" (klein) wird als Abbruch gewertet
if [ -z "$confirmation" ] || [ "$confirmation" != "ja" ]; then
    echo "Abbruch der Operation."
    exit 1
fi

# Löschen der Datenbank
echo "Löschen der Datenbank '$DB_NAME'..."
mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "DROP DATABASE IF EXISTS $DB_NAME;"
if [ $? -ne 0 ]; then
    echo "Fehler beim Löschen der Datenbank!"
    exit 1
fi

# Löschen der WordPress-Dateien
echo "Löschen der WordPress-Dateien im Verzeichnis '$WP_PATH'..."
rm -rf "$WP_PATH"
if [ $? -ne 0 ]; then
    echo "Fehler beim Löschen der WordPress-Dateien!"
    exit 1
fi

echo
printf "✅ ${GREEN}WordPress-Installation und Datenbank gelöscht.${RESET}"
echo
