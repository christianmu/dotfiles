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

# Interaktive Abfrage für den Datenbanknamen (wird auch für Namen des Installationsverzeichnisses verwendet)
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
DB_USER="admin"           # Datenbankbenutzer
DB_PASS="Flock"           # Passwort des Datenbankbenutzers
DB_HOST="localhost"       # Datenbankhost (meist localhost)

# WordPress Installationspfad
WP_URL="http://localhost/wordpress/$DB_NAME"    # URL der WordPress-Installation
WP_ADMIN_URL="$WP_URL/wp-admin"                 # Volle URL für das Dashboard

# Verzeichnis für die Installation erstellen und wechseln
mkdir -p "$WP_PATH"
sudo chown -R www-data:www-data "$WP_PATH"      # Rechte des Installationsverzeichnisses anpassen
cd "$WP_PATH" || exit 1

# WordPress herunterladen (gewählte Version oder neueste) - **US-englisch**
if [ -n "$WP_VERSION" ]; then
    echo "Lade WordPress-Version $WP_VERSION (en_US) herunter..."
    wp core download --version="$WP_VERSION" --locale=en_US
else
    echo "Lade die neueste WordPress-Version (en_US) herunter..."
    wp core download --locale=en_US
fi

# WordPress-Konfigurationsdatei erstellen
wp core config --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --extra-php <<'PHP'
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
{
echo ""
echo "/** Hochladen von Dateien über das Dashboard ohne FTP-Verbindung ermöglichen */"
echo "define('FS_METHOD', 'direct');"
echo "/** Deaktiviere automatische Updates */"
echo "define('AUTOMATIC_UPDATER_DISABLED', true);"
echo "define('WP_AUTO_UPDATE_CORE', false);"
echo "define('DISALLOW_FILE_MODS', false);"
} >> "$WP_PATH/wp-config.php"

# Datenbank erstellen
wp db create

# WordPress installieren
wp core install --url="$WP_URL" --title="$DB_NAME" --admin_email="info@musiol.io" --admin_user="Hans" --admin_password="Wilde" --skip-email

# Sprache sicher auf US-Englisch setzen (falls WP doch eine andere Sprache zieht)
wp language core install en_US
wp site switch-language en_US

# Entfernen der Standard-Plugins "Hello Dolly" und "Akismet"
echo "Entferne Standard-Plugins Hello Dolly und Akismet..."
wp plugin delete hello akismet

# Den aktuellen Benutzer zur Gruppe www-data hinzufügen (wirkt erst nach neuer Anmeldung)
sudo usermod -aG www-data "$USER"

# Rechte des Installationsverzeichnisses anpassen
sudo chown -R www-data:www-data "/var/www/html/wordpress/$DB_NAME"

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
