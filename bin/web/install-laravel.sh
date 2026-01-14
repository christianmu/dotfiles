#!/bin/bash

# 📝 Benutzer nach dem Verzeichnisnamen fragen
echo "Gewünschten Namen für die App eingeben:"
read WEBSITE_NAME

# 🔍 Verzeichnisname validieren
if ! echo "$WEBSITE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "❌ Der Verzeichnisname darf nicht leer sein, keine Leerzeichen enthalten und nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten."
    exit 1
fi

# 🔎 Sicherstellen, dass Composer installiert ist
if ! command -v composer &> /dev/null; then
    echo "❌ Composer ist nicht installiert. Bitte installiere Composer und versuche es erneut."
    exit 1
else
    echo "✅ Composer ist installiert."
fi

# 📁 Verzeichnis erstellen und Rechte setzen
echo "📂 Erstelle Laravel-Verzeichnis unter /var/www/$WEBSITE_NAME..."
sudo mkdir -p /var/www/$WEBSITE_NAME
sudo chown -R $USER:www-data /var/www/$WEBSITE_NAME
sudo chmod -R 775 /var/www/$WEBSITE_NAME
echo "✅ Verzeichnis erstellt."

# 🎯 Laravel installieren
echo "⏳ Laravel wird im Verzeichnis /var/www/$WEBSITE_NAME installiert..."
composer create-project --prefer-dist laravel/laravel /var/www/$WEBSITE_NAME
echo "✅ Laravel wurde erfolgreich installiert."

# 🔑 Besitzer- und Rechteanpassung für Laravel
echo "🔒 Setze die richtigen Berechtigungen..."
sudo chown -R www-data:www-data /var/www/$WEBSITE_NAME
sudo chmod -R 775 /var/www/$WEBSITE_NAME/storage /var/www/$WEBSITE_NAME/bootstrap/cache
echo "✅ Berechtigungen wurden gesetzt."

# 🌍 Hostname zur /etc/hosts hinzufügen
echo "🛠️ Füge $WEBSITE_NAME zu /etc/hosts hinzu..."
echo "127.0.0.1   $WEBSITE_NAME" | sudo tee -a /etc/hosts
echo "✅ Eintrag in /etc/hosts erstellt."

# 🌐 Virtual Host Konfigurationsdatei erstellen
VHOST_CONF="/etc/apache2/sites-available/$WEBSITE_NAME.conf"
echo "📝 Erstelle Apache VirtualHost-Konfiguration..."
echo "<VirtualHost *:80>
    ServerName $WEBSITE_NAME
    ServerAlias www.$WEBSITE_NAME
    DocumentRoot /var/www/$WEBSITE_NAME/public

    <Directory /var/www/$WEBSITE_NAME/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-access.log combined
</VirtualHost>" | sudo tee $VHOST_CONF
echo "✅ VirtualHost wurde erstellt."

# 🚀 Website aktivieren
echo "🛠️ Aktiviere Apache VirtualHost..."
sudo a2ensite $WEBSITE_NAME.conf
echo "✅ VirtualHost aktiviert."

# 🔄 Apache neu laden
echo "♻️ Lade Apache neu..."
sudo systemctl reload apache2
echo "✅ Apache wurde neu geladen."

# ⚙️ .env Datei konfigurieren
echo "🔧 Konfiguriere Laravel .env Datei..."
cp /var/www/$WEBSITE_NAME/.env.example /var/www/$WEBSITE_NAME/.env
sudo chown www-data:www-data /var/www/$WEBSITE_NAME/.env
sudo chmod 664 /var/www/$WEBSITE_NAME/.env
echo "✅ .env Datei eingerichtet."

# 🔑 Laravel App Key generieren
echo "🔑 Generiere Laravel App Key..."
cd /var/www/$WEBSITE_NAME
php artisan key:generate
echo "✅ Laravel App Key generiert."

# 🎉 Hinweis zum Testen ausgeben
echo -e "✅ Einrichtung abgeschlossen, Aufruf im Browser mit:\n➡️ http://$WEBSITE_NAME"
