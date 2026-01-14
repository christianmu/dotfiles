#!/bin/bash

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${YELLOW}TLS-Verschlüsselung mit Zertifikat${RESET}\n"
echo "------------------------------------------------"

# Zielverzeichnisse für Zertifikate
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

# Apache-Konfigurationsverzeichnisse
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"

# Nutzer nach Domain fragen
read -p "Bitte lokale Domain eingeben (z.B. sprechstudio): " DOMAIN

# Prüfen, ob Eingabe leer ist
if [ -z "$DOMAIN" ]; then
    echo "❌ Keine Domain eingegeben! Skript wird beendet."
    exit 1
fi

# Prüfen, ob eine Apache-Konfiguration für die Domain existiert
CONF_FILE="$APACHE_SITES_AVAILABLE/$DOMAIN.conf"

if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Fehler: Es existiert keine Apache-Konfiguration für $DOMAIN in $APACHE_SITES_AVAILABLE."
    echo "ℹ️  Bitte erst eine Apache-Konfigurationsdatei erstellen und aktivieren."
    exit 1
fi

echo "Apache-Konfiguration für $DOMAIN gefunden: $CONF_FILE"

# Webverzeichnis ermitteln (aus der bestehenden Apache-Konfiguration)
DOC_ROOT=$(grep -i "DocumentRoot" "$CONF_FILE" | awk '{print $2}')

if [ -z "$DOC_ROOT" ]; then
    DOC_ROOT="/var/www/$DOMAIN/public"  # Fallback, falls kein DocumentRoot gefunden wurde
    echo "⚠️ Kein DocumentRoot in der Apache-Konfiguration gefunden. Standardverzeichnis wird verwendet: $DOC_ROOT"
fi

# Falls Verzeichnis nicht existiert, erstellen
if [ ! -d "$DOC_ROOT" ]; then
    echo "Erstelle Webverzeichnis: $DOC_ROOT"
    mkdir -p "$DOC_ROOT"
    sudo chown -R www-data:www-data "$DOC_ROOT"
    sudo chmod -R 755 "$DOC_ROOT"
fi

echo "Erstelle Zertifikat für: $DOMAIN mit 127.0.0.1 und ::1"

# Sicherstellen, dass mkcert installiert ist
if ! command -v mkcert &> /dev/null; then
    echo "❌ Fehler: mkcert ist nicht installiert. Installiere es mit:"
    echo "    sudo apt install mkcert -y && mkcert -install"
    exit 1
fi

# Zertifikate mit mkcert erstellen
mkcert -install
mkcert -cert-file "$DOMAIN.pem" -key-file "$DOMAIN-key.pem" "$DOMAIN" 127.0.0.1 ::1

# Prüfen, ob die Zertifikate erfolgreich erstellt wurden
if [[ ! -f "$DOMAIN.pem" || ! -f "$DOMAIN-key.pem" ]]; then
    echo "❌ Fehler: Zertifikate wurden nicht erstellt!"
    exit 1
fi

echo "Verschiebe Zertifikate nach $CERT_DIR und $KEY_DIR ..."

# Dateien mit Root-Rechten verschieben
sudo mv "$DOMAIN.pem" "$CERT_DIR/$DOMAIN.pem"
sudo mv "$DOMAIN-key.pem" "$KEY_DIR/$DOMAIN-key.pem"

# Berechtigungen setzen
sudo chmod 644 "$CERT_DIR/$DOMAIN.pem"
sudo chmod 600 "$KEY_DIR/$DOMAIN-key.pem"

echo "Zertifikate erfolgreich verschoben!"

# Apache SSL-VHost Datei erstellen
SSL_CONF_FILE="$APACHE_SITES_AVAILABLE/${DOMAIN}-ssl.conf"

echo "Erstelle Apache SSL-Konfiguration für $DOMAIN ..."

sudo tee "$SSL_CONF_FILE" > /dev/null <<EOL
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $DOC_ROOT

    SSLEngine on
    SSLCertificateFile $CERT_DIR/$DOMAIN.pem
    SSLCertificateKeyFile $KEY_DIR/$DOMAIN-key.pem

    <Directory "$DOC_ROOT">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

echo "Apache SSL-Konfigurationsdatei erstellt: $SSL_CONF_FILE"

# HTTP → HTTPS Weiterleitung in bestehende .conf-Datei einfügen
echo "Ergänze HTTP → HTTPS-Weiterleitung in $CONF_FILE ..."

sudo tee "$CONF_FILE" > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $DOMAIN

    # Permanente Weiterleitung auf HTTPS
    Redirect permanent / https://$DOMAIN/

    # Logging für Fehleranalyse
    ErrorLog ${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog ${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOL

echo "HTTP → HTTPS-Weiterleitung wurde in $CONF_FILE eingetragen."

# SSL-Modul aktivieren, falls nicht aktiv
echo "SSL-Modul aktivieren..."
sudo a2enmod ssl

# Apache VHosts aktivieren
echo "Aktiviere Apache VHosts für $DOMAIN ..."
sudo a2ensite "$DOMAIN"
sudo a2ensite "${DOMAIN}-ssl"

# Apache neu starten
echo "Starte Apache neu..."
sudo systemctl restart apache2

# Erfolgsmeldung
echo
printf "✅ ${GREEN}Die Seite ist nun über HTTPS erreichbar unter: ${RESET} ${YELLOW}https://$DOMAIN ${RESET}"
echo
