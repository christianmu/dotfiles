#!/bin/bash

# Benutzer nach dem Namen der App fragen
echo "Name der App, die gelöscht werden soll (z.B. meinewebseite):"
read WEBSITE_NAME

# Validierung des Verzeichnisnamens
if ! echo "$WEBSITE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "Ungültiger Name. "
    exit 1
fi

# Sicherheitsabfrage
echo "⚠️ Löscht alle Dateien, Konfigurationen, den virtuellen Host und die SQLite-Datenbank '$WEBSITE_NAME'!"
echo "Sind Sie sicher? (ja/nein)"
read CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo "❌ Abbruch. Keine Änderungen wurden vorgenommen."
    exit 0
fi

APP_PATH="/var/www/$WEBSITE_NAME"
VHOST_CONF="/etc/apache2/sites-available/$WEBSITE_NAME.conf"

# Laravel-spezifische Bereinigungen
if [ -d "$APP_PATH" ]; then
    echo "🗑️ Lösche Installation..."

    # Laravel-Datenbank (SQLite) entfernen
    if [ -f "$APP_PATH/database/database.sqlite" ]; then
        sudo rm -f "$APP_PATH/database/database.sqlite"
        echo "✅ SQLite-Datenbank entfernt."
    fi

    # Laravel-Umgebungsdatei entfernen
    if [ -f "$APP_PATH/.env" ]; then
        sudo rm -f "$APP_PATH/.env"
        echo "✅ .env Datei entfernt."
    fi

    # Laravel Storage und Cache bereinigen
    sudo rm -rf "$APP_PATH/storage" "$APP_PATH/bootstrap/cache"

    # Gesamtes Verzeichnis entfernen
    sudo rm -rf "$APP_PATH"
    echo "✅ App-Verzeichnis wurde gelöscht."
else
    echo "ℹ️ App-Verzeichnis nicht gefunden."
fi

# Apache VirtualHost deaktivieren
if [ -f "$VHOST_CONF" ]; then
    sudo a2dissite "$WEBSITE_NAME"
    sudo rm "$VHOST_CONF"
    echo "✅ Apache VirtualHost wurde entfernt."
else
    echo "ℹ️ Apache VirtualHost nicht gefunden."
fi

# Eintrag in /etc/hosts entfernen
if grep -q "127.0.0.1   $WEBSITE_NAME" /etc/hosts; then
    sudo sed -i "/127.0.0.1   $WEBSITE_NAME/d" /etc/hosts
    echo "✅ Eintrag in /etc/hosts entfernt."
else
    echo "ℹ️ Kein Eintrag in /etc/hosts gefunden."
fi

# Apache neu starten
sudo systemctl restart apache2
echo "🔄 Apache neu gestartet."

# Abschlussmeldung
echo "✅ Alle Daten für '$WEBSITE_NAME' wurden erfolgreich gelöscht! 🚀"
