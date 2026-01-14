#!/bin/sh

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
clear
echo
printf "${YELLOW}Vollständige Installation von Virtual Host + WordPress${RESET}\n"
echo "-----------------------------------------------------------------"
printf "WordPress wird in einen Unterordner des aktuellen Verzeichnisses installiert.\n"
printf "Falls der Unterordner noch nicht existiert wird er angelegt.\n"
printf "Virtueller Host und Datenbank erhalten automatisch den Namen dieses Unterordners.\n"
printf "Links: ${YELLOW}/etc/apache2/sites-available/${RESET} ${YELLOW}/etc/hosts${RESET} ${YELLOW}${RESET} \n"
echo

# Datenbankinformationen
DB_USER="admin"
DB_PASS="Flock"
DB_HOST="localhost"

# Aktuelles Verzeichnis als Basis verwenden
BASE_DIR=$(pwd)

# Interaktive Abfrage für den Datenbanknamen (wird auch für Namen des Installationsverzeichnisses verwendet)
echo "Name für Installationsordner/Datenbank/V-Host eingeben:"
read DB_NAME

# Interaktive Abfrage für die gewünschte WordPress-Version
echo "Welche WordPress-Version soll installiert werden? (z.B. 6.4 oder leer lassen für neueste Version)"
read WP_VERSION

# Prüfen, ob der eingegebene Name gültig ist
if ! echo "$DB_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "${RED}❌ Fehler: Der Name darf nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten.${RESET}"
    exit 1
fi

# WordPress Installationspfad
PROJECT_DIR="$BASE_DIR/$DB_NAME"
WP_URL="http://$DB_NAME"
WP_ADMIN_URL="$WP_URL/wp-admin"

# Verzeichnis erstellen
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Erstelle Verzeichnis: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
else
    echo "✅ Verzeichnis existiert bereits: $PROJECT_DIR"
fi

sudo chown -R www-data:www-data "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Virtual Host einrichten
VHOST_CONF="/etc/apache2/sites-available/$DB_NAME.conf"
sudo tee "$VHOST_CONF" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DB_NAME
    DocumentRoot $PROJECT_DIR

    <Directory "$PROJECT_DIR">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DB_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$DB_NAME-access.log combined
</VirtualHost>
EOF

# Virtual Host aktivieren
sudo a2ensite "$DB_NAME.conf"
sudo systemctl reload apache2

# Hostname zur /etc/hosts hinzufügen
if ! grep -q "127.0.0.1 $DB_NAME" /etc/hosts; then
    echo "127.0.0.1   $DB_NAME" | sudo tee -a /etc/hosts
fi

# WordPress herunterladen und installieren
cd "$PROJECT_DIR"
if [ -n "$WP_VERSION" ]; then
    echo "Lade WordPress-Version $WP_VERSION herunter..."
    sudo -u chris wp core download --version="$WP_VERSION" --locale=de_DE
else
    echo "Lade die neueste WordPress-Version herunter..."
    wp core download --locale=de_DE
fi

# WordPress-Konfigurationsdatei erstellen
wp core config --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --extra-php <<PHP
define('WP_DEBUG', true);  // Anzeige von PHP-Warnings, Notices und Deprecations 
define('WP_DISABLE_FATAL_ERROR_HANDLER', true); // Anzeige von Absturzfehlern statt "freundlicher" Fehlerseite

if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
    define( 'WP_DEBUG_LOG', true ); // Fehler in die Logdatei schreiben
    define( 'WP_DEBUG_DISPLAY', true ); // Fehler im Browser anzeigen
} else {
    define( 'WP_DEBUG_LOG', false );
    define( 'WP_DEBUG_DISPLAY', false );
}

define('WP_ENVIRONMENT_TYPE', 'local'); // Umgebung festlegen, API-Zugriff ohne TLS möglich.
PHP

# Direkt-Upload ohne FTP ermöglichen
echo "" >> "$PROJECT_DIR/wp-config.php"
echo "/** Hochladen von Dateien über das Dashboard ohne FTP-Verbindung ermöglichen */" >> "$PROJECT_DIR/wp-config.php"
echo "define('FS_METHOD', 'direct');" >> "$PROJECT_DIR/wp-config.php"

echo "/** Deaktiviere automatische Updates */" >> "$PROJECT_DIR/wp-config.php"
echo "define('AUTOMATIC_UPDATER_DISABLED', true);" >> "$PROJECT_DIR/wp-config.php"
echo "define('WP_AUTO_UPDATE_CORE', false);" >> "$PROJECT_DIR/wp-config.php"
echo "define('DISALLOW_FILE_MODS', false);" >> "$PROJECT_DIR/wp-config.php"

# Datenbank erstellen 
wp db create

# WordPress installieren
wp core install --url="$WP_URL" --title="$DB_NAME" --admin_user="Hans" --admin_password="Wilde" --admin_email="info@musiol.io"

# Permalinkstruktur auf "Beitragsname" setzen
echo "Setze Permalinkstruktur auf 'Beitragsname'..."
wp option update permalink_structure "/%postname%/"

# Entfernen der Standard-Plugins "Hello Dolly" und "Akismet"
echo "Entferne Standard-Plugins Hello Dolly und Akismet..."
wp plugin delete hello akismet

# Alle vorhandenen Themes löschen
echo "Lösche alle vorhandenen Themes..."
wp theme list --field=name | xargs wp theme delete

# Den aktuellen Benutzer zur Gruppe www-data hinzufügen
sudo usermod -aG www-data $USER

# Rechte des Installationsverzeichnisses anpassen
sudo chown -R www-data:www-data "$PROJECT_DIR"

# .htaccess Datei erstellen (mit Sicherheit)
sudo touch "$PROJECT_DIR/.htaccess"
sudo chmod 664 "$PROJECT_DIR/.htaccess"
sudo tee "$PROJECT_DIR/.htaccess" > /dev/null <<EOF
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF

# Apache Modul aktivieren (falls nicht aktiviert)
sudo a2enmod rewrite
sudo systemctl restart apache2

# Permalinkstruktur neu speichern, um WordPress zu "triggern"
wp rewrite flush --hard

# Bestätigung, ob Datei erstellt wurde
if [ -f "$PROJECT_DIR/.htaccess" ]; then
    echo ".htaccess wurde erfolgreich erstellt."
else
    echo "❌ Fehler: .htaccess konnte nicht erstellt werden."
fi

# Erfolgsmeldung
echo
printf "✅ ${GREEN}WordPress und Virtual Host sind erfolgreich eingerichtet. Erreichbar unter:${RESET}\n"
echo "${YELLOW}http://$DB_NAME ${RESET}\n"
printf "${GREEN}.htaccess:${RESET} ${YELLOW}file://$PROJECT_DIR/.htaccess${RESET}\n"
printf "${GREEN}registrierte V-Hosts:${RESET} ${YELLOW}file:///etc/hosts${RESET}\n"
printf "${GREEN}Konfiguration der Hosts:${RESET} ${YELLOW}file:///etc/apache2/sites-available/${RESET}\n"

# WordPress-Admin-Dashboard im Standardbrowser öffnen
xdg-open "$WP_ADMIN_URL"

# WordPress-Seite im Standardbrowser öffnen
xdg-open "$WP_URL"
echo
