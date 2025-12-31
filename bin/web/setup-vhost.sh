#!/bin/bash

# Benutzer nach dem Verzeichnisnamen fragen
echo "Bitte geben Sie den Namen der Website ein (z.B. meinewebseite):"
read WEBSITE_NAME

# Verzeichnisname validieren
if ! echo "$WEBSITE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "Der Verzeichnisname darf nicht leer sein, keine Leerzeichen enthalten und nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten."
    exit 1
fi

# Verzeichnis erstellen und Rechte setzen
sudo mkdir -p /var/www/$WEBSITE_NAME
sudo chown -R $USER:www-data /var/www/$WEBSITE_NAME
sudo chmod -R 755 /var/www/$WEBSITE_NAME

# Hostname zur /etc/hosts hinzufügen
echo "127.0.0.1   $WEBSITE_NAME.local" | sudo tee -a /etc/hosts

# Virtual Host Konfigurationsdatei erstellen
VHOST_CONF="/etc/apache2/sites-available/$WEBSITE_NAME.conf"
echo "<VirtualHost *:80>
	ServerName $WEBSITE_NAME.local
	ServerAlias www.$WEBSITE_NAME.local
	DocumentRoot /var/www/$WEBSITE_NAME

	<Directory /var/www/$WEBSITE_NAME>
		Options Indexes FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>

	ErrorLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-error.log
	CustomLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-access.log combined
</VirtualHost>" | sudo tee $VHOST_CONF

# Website aktivieren
sudo a2ensite $WEBSITE_NAME.conf

# Apache neu laden
sudo systemctl reload apache2

# Probeseite erstellen
echo "<h1>Willkommen bei $WEBSITE_NAME.local</h1>" | sudo tee /var/www/$WEBSITE_NAME/index.html

# Hinweis zum Testen ausgeben
echo "Die Einrichtung ist abgeschlossen. Sie können die Seite unter http://$WEBSITE_NAME.local aufrufen."

