#!/bin/bash

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${YELLOW}Einrichtung eines Virtuellen Hosts${RESET}\n"
echo "----------------------------------"

# Aktuelles Verzeichnis als Basis verwenden
BASE_DIR=$(pwd)
BASE_NAME=$(basename "$BASE_DIR")

# Benutzer nach dem Unterordner fragen
echo "Der V-Host wird im Arbeitsverzeichnis unter dem Namen des zu wählenden Ordners registriert in:"
echo "/etc/hosts"
echo "Spätere Anpassung des Startverzeichnisses der App per DocumentRoot unter: "
echo "/etc/apache2/sites-available/"
echo
read -p "Ordnername eingeben (z.B. meineapp): " SUBFOLDER
echo

# Prüfen, ob der eingegebene Name gültig ist
if ! echo "$SUBFOLDER" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "❌ Fehler: Der Name darf nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten. Leerzeichen sind nicht erlaubt."
    exit 1
fi

# Vollständiger Pfad zum Projektverzeichnis
PROJECT_DIR="$BASE_DIR/$SUBFOLDER"

# Verzeichnis erstellen, falls es nicht existiert
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Erstelle Verzeichnis: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
else
    echo "Verzeichnis existiert bereits: $PROJECT_DIR"
fi

# Besitzer und Rechte setzen
sudo chown -R $USER:www-data "$PROJECT_DIR"
sudo chmod -R 755 "$PROJECT_DIR"

# Hostname zur /etc/hosts hinzufügen (falls noch nicht vorhanden)
if ! grep -q "127.0.0.1 $SUBFOLDER" /etc/hosts; then
    echo "127.0.0.1   $SUBFOLDER" | sudo tee -a /etc/hosts
fi

# Virtual Host Konfigurationsdatei erstellen
VHOST_CONF="/etc/apache2/sites-available/$SUBFOLDER.conf"

echo "Erstelle VirtualHost für $SUBFOLDER ..."

echo "<VirtualHost *:80>
    ServerName $SUBFOLDER
    ServerAlias www.$SUBFOLDER
    DocumentRoot $PROJECT_DIR

    <Directory \"$PROJECT_DIR\">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$SUBFOLDER-error.log
    CustomLog \${APACHE_LOG_DIR}/$SUBFOLDER-access.log combined
</VirtualHost>" | sudo tee "$VHOST_CONF"

# Website aktivieren
sudo a2ensite "$SUBFOLDER.conf"

# Apache neu laden
sudo systemctl reload apache2

# Probeseite erstellen (falls nicht vorhanden)
if [ ! -f "$PROJECT_DIR/index.html" ]; then
    echo "<h1>Willkommen bei $SUBFOLDER</h1>" | sudo tee "$PROJECT_DIR/index.html"
fi

# Erfolgsmeldung
echo
printf "${GREEN}✅ Der V-Host ist eingerichtet. Erreichbar unter:${RESET} ${YELLOW}http://$SUBFOLDER${RESET}\n"

