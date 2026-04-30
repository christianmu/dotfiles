#!/bin/bash

# Farben
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# === Parameter oder Interaktiv ===
SRC="$1"
DEST="$2"

if [[ -z "$SRC" ]]; then
    echo -ne "${YELLOW}Welche WordPress-Installation möchtest du kopieren? (Quellordner): ${RESET}"
    read SRC
fi

if [[ -z "$DEST" ]]; then
    echo -ne "${YELLOW}Wie soll die neue Installation heißen? (Zielordner): ${RESET}"
    read DEST
fi

# === Pfade und DB-Zugänge ===
WP_DIR="/var/www/html/wordpress"
WP_SRC_PATH="$WP_DIR/$SRC"
WP_DEST_PATH="$WP_DIR/$DEST"
SQL_DUMP="/tmp/${SRC}.sql"
DB_USER="admin"
DB_PASS="Flock"
DB_HOST="localhost"
DB_NAME="$DEST"
WP_URL="http://localhost/wordpress/$DEST"
WP_ADMIN_URL="$WP_URL/wp-admin"

# === Prüfungen ===
if [[ -d "$WP_DEST_PATH" ]]; then
    echo -e "${RED}❌ Zielverzeichnis '$DEST' existiert bereits unter $WP_DEST_PATH.${RESET}"
    exit 1
fi

if [[ ! -d "$WP_SRC_PATH" ]]; then
    echo -e "${RED}❌ Quellverzeichnis '$SRC' existiert nicht unter $WP_DIR.${RESET}"
    exit 1
fi

if ! command -v wp &> /dev/null; then
    echo -e "${RED}❌ wp-cli ist nicht installiert oder nicht im Pfad.${RESET}"
    exit 1
fi

# === Installation starten ===
echo
echo -e "${YELLOW}📦 Installiere neue WordPress-Instanz in '$DEST'...${RESET}"
echo "-------------------------------------------"

mkdir -p "$WP_DEST_PATH"
sudo chown -R www-data:www-data "$WP_DEST_PATH"
cd "$WP_DEST_PATH" || exit 1

echo "📥 Lade neueste WordPress-Version..."
wp core download --locale=de_DE

echo "⚙️  Konfiguriere wp-config.php..."
wp core config --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --extra-php <<PHP
define('WP_DEBUG', true);
define('WP_DISABLE_FATAL_ERROR_HANDLER', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);
define('WP_ENVIRONMENT_TYPE', 'local');
PHP

cat <<EOL >> wp-config.php
define('FS_METHOD', 'direct');
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);
define('DISALLOW_FILE_MODS', false);
EOL

echo "🛢️  Erstelle leere Datenbank..."
wp db create

echo "🧬 Exportiere Datenbank aus '$SRC'..."
wp db export "$SQL_DUMP" --path="$WP_SRC_PATH"

echo "📥 Importiere in '$DEST'..."
wp db import "$SQL_DUMP"

echo "📁 Kopiere wp-content von '$SRC'..."
rm -rf "$WP_DEST_PATH/wp-content"
cp -r "$WP_SRC_PATH/wp-content" "$WP_DEST_PATH/"
sudo chown -R www-data:www-data "$WP_DEST_PATH"

HTACCESS="$WP_DEST_PATH/.htaccess"
cat <<EOF | sudo tee "$HTACCESS" > /dev/null
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /wordpress/$DEST/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /wordpress/$DEST/index.php [L]
</IfModule>
# END WordPress
EOF
sudo chmod 664 "$HTACCESS"

echo "🔗 Setze Permalinkstruktur..."
wp option update permalink_structure "/%postname%/"
wp rewrite flush --hard

echo "🔄 Ersetze URLs in der Datenbank:"
OLD_URL="http://localhost/wordpress/$SRC"
NEW_URL="$WP_URL"
wp search-replace "$OLD_URL" "$NEW_URL" --all-tables --quiet

rm -f "$SQL_DUMP"

echo
echo -e "✅ ${GREEN}Fertig! WordPress-Kopie '${DEST}' ist erreichbar unter:${RESET}"
echo "   → $WP_URL"
echo "   → Dashboard: $WP_ADMIN_URL (Benutzer: Hans / Passwort: Wilde)"

if command -v xdg-open &> /dev/null; then
    xdg-open "$WP_URL"
    xdg-open "$WP_ADMIN_URL"
    xdg-open "http://localhost/phpmyadmin"
fi
