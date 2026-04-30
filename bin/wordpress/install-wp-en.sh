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
printf "+ Erstellt WordPress im einzugebenden Unterordner des Verzeichnisses ${YELLOW}/var/www/html/wordpress/${RESET}.\n"
printf "+ In welchem Verzeichnis diese Datei ausgeführt wird, spielt keine Rolle.\n"
printf "+ Die Datenbank erhält den selben Namen wie dieser Unterordner.\n"
echo

# Interaktive Abfrage für den Datenbanknamen
echo "Name für Installationsordner/Datenbank eingeben:"
read DB_NAME

# Prüfen auf leere Eingabe
if [ -z "$DB_NAME" ]; then
    printf "${RED}Fehler: Kein Name eingegeben.${RESET}\n"
    exit 1
fi

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
DB_USER="admin"
DB_PASS="Flock"
DB_HOST="localhost"

# WordPress Installationspfad
WP_URL="http://localhost/wordpress/$DB_NAME"
WP_ADMIN_URL="$WP_URL/wp-admin"

# Verzeichnis für die Installation erstellen und wechseln
mkdir -p "$WP_PATH"
sudo chown -R www-data:www-data "$WP_PATH"
cd "$WP_PATH" || exit 1

# WordPress herunterladen (gewählte Version oder neueste) - US-englisch
if [ -n "$WP_VERSION" ]; then
    echo "Lade WordPress-Version $WP_VERSION (en_US) herunter..."
    wp core download --version="$WP_VERSION" --locale=en_US
else
    echo "Lade die neueste WordPress-Version (en_US) herunter..."
    wp core download --locale=en_US
fi

# WordPress-Konfigurationsdatei erstellen
wp core config --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --extra-php <<'PHP'
define('WP_DEBUG', true);
define('WP_DISABLE_FATAL_ERROR_HANDLER', true);

if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
    define( 'WP_DEBUG_LOG', true );
    define( 'WP_DEBUG_DISPLAY', true );
} else {
    define( 'WP_DEBUG_LOG', false );
    define( 'WP_DEBUG_DISPLAY', false );
}

define('WP_ENVIRONMENT_TYPE', 'local');

/** Hochladen von Dateien über das Dashboard ohne FTP-Verbindung ermöglichen */
define('FS_METHOD', 'direct');

/** Deaktiviere automatische Updates */
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);
define('DISALLOW_FILE_MODS', false);
PHP

# Datenbank erstellen
wp db create

# WordPress installieren
wp core install \
  --url="$WP_URL" \
  --title="$DB_NAME" \
  --admin_email="info@musiol.io" \
  --admin_user="Hans" \
  --admin_password="Wilde" \
  --skip-email

# Sprache sicher auf US-Englisch setzen
wp language core install en_US
wp site switch-language en_US

# Entfernen der Standard-Plugins
echo "Entferne Standard-Plugins Hello Dolly und Akismet..."
wp plugin delete hello akismet

# Rechte des Installationsverzeichnisses anpassen
sudo chown -R www-data:www-data "$WP_PATH"

# .htaccess Datei erstellen
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

# Permalinkstruktur neu speichern
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