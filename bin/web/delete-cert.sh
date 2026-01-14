#!/bin/bash

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${YELLOW}Beenden von TLS sowie Zertifikatslöschung einer Domain${RESET}\n"
echo "------------------------------------------------------"
printf "+ Deaktivierung der .ssl.conf-Konfigurationsdatei des Webservers für <VirtualHost *:443> mit anschließender Löschung: ${YELLOW}/etc/apache2/sites-available/${RESET}\n"
printf "+ Entfernung HTTPS-Weiterleitung aus .conf-Konfigurationsdatei <VirtualHost *:80>\n"
printf "+ Wiederbefüllung <VirtualHost *:80> in .conf-Konfigurationsdatei\n"
printf "+ Zertifikatslöschung der .pem-Datei ${YELLOW}/etc/ssl/certs/${RESET} und Schlüsseldatei -key.pem ${YELLOW}/etc/ssl/private/${RESET}\n"
echo

# Apache-Konfigurationsverzeichnisse
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"

# SSL-Zertifikatsverzeichnisse
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

# Nutzer nach Domain fragen
read -p "Bitte lokale Domain eingeben (z.B. sprechstudio): " DOMAIN

# Prüfen, ob Eingabe leer ist
if [ -z "$DOMAIN" ]; then
    echo "❌ Keine Domain eingegeben! Skript wird beendet."
    exit 1
fi

# **1️⃣ SSL-Konfigurationsdatei für die Domain deaktivieren und löschen**
SSL_CONF_FILE="$APACHE_SITES_AVAILABLE/${DOMAIN}-ssl.conf"
if [ -f "$SSL_CONF_FILE" ]; then
    echo "Deaktiviere und lösche die SSL-Konfigurationsdatei für $DOMAIN: $SSL_CONF_FILE"
    sudo a2dissite "${DOMAIN}-ssl"
    sudo rm -f "$SSL_CONF_FILE"
    sudo rm -f "$APACHE_SITES_ENABLED/${DOMAIN}-ssl.conf"
else
    echo "Keine SSL-Konfigurationsdatei für $DOMAIN gefunden. Weiter mit HTTP-VHost."
fi

# **2️⃣ Prüfen, ob eine Apache-Konfiguration für die Domain existiert**
CONF_FILE="$APACHE_SITES_AVAILABLE/$DOMAIN.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Fehler: Es existiert keine Apache-Konfiguration für $DOMAIN in $APACHE_SITES_AVAILABLE."
    exit 1
fi

# **3️⃣ HTTPS-Weiterleitung aus HTTP-Konfiguration entfernen**
echo "Entferne HTTPS-Weiterleitung aus $CONF_FILE ..."
sudo sed -i '/Redirect permanent \/ https:\/\//d' "$CONF_FILE"

# **4️⃣ Ursprüngliche HTTP-Konfiguration wiederherstellen (falls nötig)**
if ! grep -q "DocumentRoot" "$CONF_FILE"; then
    echo "Stelle ursprüngliche Apache-Konfiguration für $DOMAIN wieder her..."
    sudo tee "$CONF_FILE" > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/$DOMAIN

    <Directory "/var/www/$DOMAIN">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOL
fi

echo "Apache-Konfiguration für $DOMAIN wurde zurückgesetzt!"

# **5️⃣ SSL-Zertifikate für die Domain entfernen**
echo "Entferne Zertifikate für $DOMAIN..."
sudo rm -f "$CERT_DIR/$DOMAIN.pem"
sudo rm -f "$KEY_DIR/$DOMAIN-key.pem"

# **6️⃣ SSL-Modul bleibt aktiv, andere SSL-Sites bleiben unberührt**
echo "Andere SSL-Sites bleiben aktiv, SSL-Modul wird nicht deaktiviert."

# **7️⃣ Apache-VHost für HTTP reaktivieren**
echo "Aktiviere HTTP-VHost für $DOMAIN ..."
sudo a2ensite "$DOMAIN"

# **8️⃣ Apache neu starten**
echo "Starte Apache neu..."
sudo systemctl restart apache2

# Erfolgsmeldung
echo
printf "✅ ${GREEN}Die Seite ist nun wieder über HTTP erreichbar unter:${RESET}" 
printf "${YELLOW}http://$DOMAIN ${RESET}"
echo
