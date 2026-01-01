#!/bin/sh

# Farben definieren
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Begrüßungsnachricht
echo
printf "${YELLOW}Installation einer WordPress-Instanz${RESET}\n"
echo "------------------------------------"
printf "+ Erstellt WordPress im einzugebenden Unterordner des Verzeichnisses ${YELLOW}/var/www/html/wordpress/${RESET}. \n"
printf "+ Die Datenbank erhält den selben Namen wie dieser Unterordner.\n"
printf "+ Kadence Blocks/Theme werden installiert/aktiviert.\n"
echo

# Interaktive Abfrage für den Datenbanknamen (wird auch für Namen des Installationsverzeichnisses verwendet)
echo "Name für Installationsordner/Datenbank eingeben:"
read DB_NAME

# Überprüfen, ob das Verzeichnis bereits existiert
WP_PATH="/var/www/html/wordpress/$DB_NAME"
if [ -d "$WP_PATH" ]; then
    printf "${RED}Fehler: Das Verzeichnis $WP_PATH existiert bereits. Bitte wähle einen anderen Namen.${RESET}\n"
    exit 1
fi

# Interaktive Abfrage für die gewünschte WordPress-Version
echo "Welche WordPress-Version soll installiert werden? (z.B. 6.2.2 oder leer lassen für neueste Version)"
read WP_VERSION

# Datenbankinformationen
DB_USER="admin"           # Datenbankbenutzer
DB_PASS="Flock"           # Passwort des Datenbankbenutzers
DB_HOST="localhost"       # Datenbankhost (meist localhost)

# WordPress Installationspfad
WP_PATH="/var/www/html/wordpress/$DB_NAME"
WP_URL="http://localhost/wordpress/$DB_NAME"    # URL der WordPress-Installation
WP_ADMIN_URL="$WP_URL/wp-admin"                # Volle URL für das Dashboard

# Verzeichnis für die Installation erstellen und wechseln
mkdir -p "$WP_PATH"
sudo chown -R www-data:www-data "$WP_PATH"      # Rechte des Installationsverzeichnisses anpassen
cd "$WP_PATH"

# WordPress herunterladen (gewählte Version oder neueste)
if [ -n "$WP_VERSION" ]; then
    echo "Lade WordPress-Version $WP_VERSION herunter..."
    wp core download --version="$WP_VERSION" --locale=de_DE
else
    echo "Lade die neueste WordPress-Version herunter..."
    wp core download --locale=en_US
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
echo "" >> "$WP_PATH/wp-config.php"
echo "/** Hochladen von Dateien über das Dashboard ohne FTP-Verbindung ermöglichen */" >> "$WP_PATH/wp-config.php"
echo "define('FS_METHOD', 'direct');" >> "$WP_PATH/wp-config.php"

# Deaktivierung automatischer Updates
echo "/** Deaktiviere automatische Updates */" >> "$WP_PATH/wp-config.php"
echo "define('AUTOMATIC_UPDATER_DISABLED', true);" >> "$WP_PATH/wp-config.php"
echo "define('WP_AUTO_UPDATE_CORE', false);" >> "$WP_PATH/wp-config.php"
echo "define('DISALLOW_FILE_MODS', false);" >> "$WP_PATH/wp-config.php"

# Datenbank erstellen
wp db create

# WordPress installieren
wp core install --url="$WP_URL" --title="$DB_NAME" --admin_email="info@musiol.io" --admin_user="Hans" --admin_password="Wilde"

# Entfernen der Standard-Plugins "Hello Dolly" und "Akismet"
echo "Entferne Standard-Plugins Hello Dolly und Akismet..."
wp plugin delete hello akismet

# Kadence-Theme installieren und aktivieren
echo "Installiere und aktiviere das Kadence-Theme..."
wp theme install kadence --activate

# Alle sonstigen Themes löschen
echo "Lösche alle sonstigen Themes..."
wp theme list --field=name | grep -v "kadence" | xargs wp theme delete

# Die gewünschten Plugins installieren und aktivieren
echo "Installiere und aktiviere Kadence Blocks und Starter Templates..."
wp plugin install kadence-blocks --activate
wp plugin install kadence-starter-templates --activate

# Den aktuellen Benutzer zur Gruppe www-data hinzufügen
sudo usermod -aG www-data $USER

# Rechte des Installationsverzeichnisses anpassen
sudo chown -R www-data:www-data /var/www/html/wordpress/$DB_NAME

# .htaccess Datei erstellen (mit Sicherheit)
sudo touch "$WP_PATH/.htaccess"
sudo chmod 664 "$WP_PATH/.htaccess"
sudo tee "$WP_PATH/.htaccess" > /dev/null <<EOF
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /wordpress/$DB_NAME/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /wordpress/$DB_NAME/index.php [L]
</IfModule>
# END WordPress
EOF

# Bestätigung, ob Datei erstellt wurde
if [ -f "$WP_PATH/.htaccess" ]; then
    echo "✅ .htaccess wurde erstellt."
else
    echo "❌ Fehler: .htaccess konnte nicht erstellt werden."
fi

# Permalinkstruktur auf "Beitragsname" setzen
echo "Setze Permalinkstruktur auf 'Beitragsname'..."
wp option update permalink_structure "/%postname%/"

# Permalinkstruktur neu speichern, um WordPress zu "triggern"
wp rewrite flush --hard

# Zeitzone und Formate setzen
echo "Setze Zeitzone und Datums-/Zeitformat..."
wp option update timezone_string "Europe/Berlin"
wp option update date_format "j. F Y"
wp option update time_format "H:i"

echo
printf "✅ ${YELLOW}http://localhost/wordpress/$DB_NAME${RESET}\n"
echo

# phpMyAdmin öffnen
xdg-open "http://localhost/phpmyadmin"

# WordPress-Admin-Dashboard im Standardbrowser öffnen
xdg-open "$WP_ADMIN_URL"

# WordPress-Seite im Standardbrowser öffnen
xdg-open "$WP_URL"
