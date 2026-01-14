#!/bin/sh

# Datenbankinformationen
DB_USER="admin"           # Datenbankbenutzer
DB_PASS="Flock"           # Passwort des Datenbankbenutzers
DB_HOST="localhost"       # Datenbankhost (meist localhost)

# Aktuelles Verzeichnis als Basis verwenden
BASE_DIR=$(pwd)


# Interaktive Abfrage für den Datenbanknamen (wird auch für Namen des Installationsverzeichnisses verwendet)
echo "Name für Installationsordner/Datenbank eingeben:"
read DB_NAME

# WordPress Installationspfad im Dateisystem, URLs im Browser
WP_PATH="$BASE_DIR/$DB_NAME"
WP_URL="http://$DB_NAME"                       
WP_ADMIN_URL="$WP_URL/wp-admin"                

# Interaktive Abfrage für die gewünschte WordPress-Version
echo "Welche WordPress-Version soll installiert werden? (z.B. 6.2.2 oder leer lassen für neueste Version)"
read WP_VERSION

# Prüfen, ob der eingegebene Name gültig ist
if ! echo "$DB_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "${RED}❌ Fehler: Der Name darf nur Buchstaben, Zahlen, Bindestriche oder Unterstriche enthalten.${RESET}"
    exit 1
fi

# Verzeichnis für die Installation erstellen und wechseln
if [ ! -d "$WP_PATH" ]; then
    echo "Erstelle Verzeichnis: $WP_PATH"
    mkdir -p "$WP_PATH"
else
    echo "✅ Verzeichnis existiert bereits: $WP_PATH"
fi
sudo chown -R www-data:www-data "$WP_PATH"      # Rechte des Installationsverzeichnisses anpassen
cd "$WP_PATH"

# WordPress herunterladen (gewählte Version oder neueste)
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
wp core install --url="$WP_URL" --title="$DB_NAME" --admin_user="Hans" --admin_password="Wilde" --admin_email="info@musiol.io"

# Entfernen der Standard-Plugins "Hello Dolly" und "Akismet"
echo "Entferne Standard-Plugins Hello Dolly und Akismet..."
wp plugin delete hello akismet

# Alle vorhandenen Themes löschen
echo "Lösche alle vorhandenen Themes..."
wp theme list --field=name | xargs wp theme delete

# Den aktuellen Benutzer zur Gruppe www-data hinzufügen
sudo usermod -aG www-data $USER

# Rechte des Installationsverzeichnisses anpassen
sudo chown -R www-data:www-data "$WP_PATH"

# .htaccess Datei erstellen (mit Sicherheit)
sudo touch "$WP_PATH/.htaccess"
sudo chmod 664 "$WP_PATH/.htaccess"
sudo tee "$WP_PATH/.htaccess" > /dev/null <<EOF
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

# Bestätigung, ob Datei erstellt wurde
if [ -f "$WP_PATH/.htaccess" ]; then
    echo "✅ .htaccess wurde erfolgreich erstellt."
else
    echo "❌ Fehler: .htaccess konnte nicht erstellt werden."
fi

# Permalinkstruktur auf "Beitragsname" setzen
echo "Setze Permalinkstruktur auf 'Beitragsname'..."
wp option update permalink_structure "/%postname%/"

# Permalinkstruktur neu speichern, um WordPress zu "triggern"
wp rewrite flush --hard

# phpMyAdmin öffnen
xdg-open "http://localhost/phpmyadmin"

# WordPress-Admin-Dashboard im Standardbrowser öffnen
xdg-open "$WP_ADMIN_URL"

# WordPress-Seite im Standardbrowser öffnen
xdg-open "$WP_URL"
