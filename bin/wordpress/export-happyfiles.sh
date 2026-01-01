#!/bin/bash

echo "📤 Exportiere HappyFiles-Daten..."

read -p "📁 Pfad zur WordPress-Instanz (z.B. /var/www/html/wordpress/luigis.local): " WP_PATH
EXPORT_DIR="$WP_PATH/happyfiles-export-$(date +%Y-%m-%d)"
mkdir -p "$EXPORT_DIR"

# Lade DB-Zugangsdaten aus wp-config.php
DB_NAME=$(grep DB_NAME "$WP_PATH/wp-config.php" | cut -d "'" -f 4)
DB_USER=$(grep DB_USER "$WP_PATH/wp-config.php" | cut -d "'" -f 4)
DB_PASS=$(grep DB_PASSWORD "$WP_PATH/wp-config.php" | cut -d "'" -f 4)
DB_HOST=$(grep DB_HOST "$WP_PATH/wp-config.php" | cut -d "'" -f 4)

# Ordnerstruktur exportieren
echo "📄 Exportiere Ordnerstruktur..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" --batch --raw -e "
  SELECT term_id, name, slug
  FROM wp_terms
  WHERE term_id IN (
    SELECT term_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
  );
" | sed 's/\t/","/g; s/^/"/; s/$/"/' > "$EXPORT_DIR/happyfiles-terms.csv"

# Term-Metadaten exportieren
echo "🔧 Exportiere Term-Metadaten..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" --batch --raw -e "
  SELECT meta_id, term_id, meta_key, meta_value
  FROM wp_termmeta
  WHERE term_id IN (
    SELECT term_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
  );
" | sed 's/\t/","/g; s/^/"/; s/$/"/' > "$EXPORT_DIR/happyfiles-metadata.csv"

# Medien-Zuordnungen exportieren
echo "🔗 Exportiere Medien-Zuordnungen..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" --batch --raw -e "
  SELECT object_id, term_taxonomy_id
  FROM wp_term_relationships
  WHERE term_taxonomy_id IN (
    SELECT term_taxonomy_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
  );
" | sed 's/\t/","/g; s/^/"/; s/$/"/' > "$EXPORT_DIR/happyfiles-media.csv"

# Uploads kopieren
echo "📦 Packe uploads..."
UPLOADS_SRC=$(php -r "define('WP_USE_THEMES', false); require('$WP_PATH/wp-load.php'); echo wp_get_upload_dir()['basedir'];")

if [ -d "$UPLOADS_SRC" ]; then
  mkdir -p "$EXPORT_DIR/uploads"
  cp -r "$UPLOADS_SRC/." "$EXPORT_DIR/uploads/"
else
  echo "⚠️ Upload-Verzeichnis nicht gefunden!"
fi

echo "✅ Export abgeschlossen!"
echo "📂 Exportordner: $EXPORT_DIR"
