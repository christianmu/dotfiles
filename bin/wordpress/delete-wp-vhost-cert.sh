#!/bin/sh

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${YELLOW}Entfernung von Virtual Host + WordPress${RESET}\n"
echo "-----------------------------------------------------------------"
printf "+ Entfernt WordPress-Instanz/Datenbank/Installationsordner/V-Host/SSL-Zertifikate\n"
printf "+ Als Basisverzeichnis dient der aktuelle Ordner\n"
echo

# Datenbankinformationen
DB_USER="admin"
DB_PASS="Flock"
DB_HOST="localhost"

# Apache-Konfigurationsverzeichnisse
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"

# SSL-Zertifikatsverzeichnisse
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

# Aktuelles Verzeichnis als Basis verwenden
BASE_DIR=$(pwd)

# Interaktive Abfrage für den Installationsordner/Datenbank/V-Host-Namen
read -p "Name des zu entfernenden Installationsordners/Datenbank/V-Host: " DB_NAME

# Pfad zum Projektverzeichnis
PROJECT_DIR="$BASE_DIR/$DB_NAME"

# Bestätigung der Entfernung
read -p "Bist du sicher, dass du $DB_NAME samt Datenbank, virtuellem Host und Installationsverzeichnis entfernen möchtest? (j/n) " CONFIRM

if [ "$CONFIRM" != "j" ]; then
    echo "${RED}❌ Abbruch: Der Löschvorgang wurde nicht bestätigt.${RESET}"
    exit 1
fi

# Virtuellen Host deaktivieren und Konfigurationsdatei löschen
sudo a2dissite "$DB_NAME.conf"
sudo rm -f "$APACHE_SITES_AVAILABLE/$DB_NAME.conf"
sudo systemctl reload apache2

# Entfernen des Eintrags in /etc/hosts
sudo sed -i "/127.0.0.1   $DB_NAME/d" /etc/hosts

# Prüfen und Löschen von SSL-Konfigurationen
SSL_CONF_FILE="$APACHE_SITES_AVAILABLE/${DB_NAME}-ssl.conf"
if [ -f "$SSL_CONF_FILE" ]; then
    echo "Deaktiviere und lösche SSL-Konfigurationsdatei: $SSL_CONF_FILE"
    sudo a2dissite "${DB_NAME}-ssl"
    sudo rm -f "$SSL_CONF_FILE"
    sudo rm -f "$APACHE_SITES_ENABLED/${DB_NAME}-ssl.conf"
fi

# Löschen der Zertifikate
sudo rm -f "$CERT_DIR/$DB_NAME.pem"
sudo rm -f "$KEY_DIR/$DB_NAME-key.pem"

# Löschen des Projektverzeichnisses
if [ -d "$PROJECT_DIR" ]; then
    sudo rm -rf "$PROJECT_DIR"
    printf "\n✅ ${GREEN}Verzeichnis $PROJECT_DIR wurde erfolgreich gelöscht.${RESET}"
else
    echo "${RED}❌ Verzeichnis $PROJECT_DIR nicht gefunden.${RESET}"
fi

# Löschen der Datenbank
mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"

# Erfolgsmeldung
printf "\n✅ ${GREEN}Datenbank, SSL-Zertifikate und der virtuelle Host sind erfolgreich entfernt. Die WordPress-Installation kann evtl. noch in anderem Verzeichnis liegen.${RESET}\n"
