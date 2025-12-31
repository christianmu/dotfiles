#!/bin/bash

# Benutzer nach dem Namen der Website fragen
echo "Bitte geben Sie den Namen der Website ein, die gelöscht werden soll (z.B. meinewebseite):"
read WEBSITE_NAME

# Validierung des Verzeichnisnamens
if ! echo "$WEBSITE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "Ungültiger Verzeichnisname. Der Name darf nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten."
    exit 1
fi

# Sicherheitsabfrage
echo "WARNUNG: Dies wird alle Dateien und Konfigurationen für '$WEBSITE_NAME' löschen. Möchten Sie fortfahren? (ja/nein)"
read CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo "Abbruch. Keine Änderungen wurden vorgenommen."
    exit 0
fi

# Website-Verzeichnis löschen
if [ -d "/var/www/$WEBSITE_NAME" ]; then
    sudo rm -rf /var/www/$WEBSITE_NAME
    echo "Website-Verzeichnis /var/www/$WEBSITE_NAME wurde gelöscht."
else
    echo "Website-Verzeichnis /var/www/$WEBSITE_NAME wurde nicht gefunden."
fi

# Apache-Konfigurationsdateien löschen
SITE_CONF="/etc/apache2/sites-available/$WEBSITE_NAME.conf"
if [ -f "$SITE_CONF" ]; then
    sudo rm "$SITE_CONF"
    echo "Konfigurationsdatei $SITE_CONF wurde gelöscht."
else
    echo "Konfigurationsdatei $SITE_CONF wurde nicht gefunden."
fi

SITE_ENABLED="/etc/apache2/sites-enabled/$WEBSITE_NAME.conf"
if [ -f "$SITE_ENABLED" ]; then
    sudo rm "$SITE_ENABLED"
    echo "Symbolischer Link $SITE_ENABLED wurde gelöscht."
else
    echo "Symbolischer Link $SITE_ENABLED wurde nicht gefunden."
fi

# Eintrag in /etc/hosts entfernen
if grep -q "127.0.0.1   $WEBSITE_NAME.local" /etc/hosts; then
    sudo sed -i "/127.0.0.1   $WEBSITE_NAME.local/d" /etc/hosts
    echo "Eintrag in /etc/hosts wurde entfernt."
else
    echo "Kein Eintrag in /etc/hosts für $WEBSITE_NAME.local gefunden."
fi

# Apache neu laden
sudo systemctl reload apache2

# Abschlussmeldung
echo "Alle Daten für '$WEBSITE_NAME' wurden gelöscht."

