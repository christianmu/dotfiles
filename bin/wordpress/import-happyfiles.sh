#!/bin/bash

echo "📥 Importiere HappyFiles-Daten..."

read -p "📁 Quellpfad zur WordPress-Instanz (z.B. /var/www/html/wordpress/quelle): " SOURCE_PATH
read -p "📁 Zielpfad zur WordPress-Instanz (z.B. /var/www/html/wordpress/ziel): " TARGET_PATH

EXPORT_DIR="$SOURCE_PATH/happyfiles-export-$(date +%Y-%m-%d)"

if [ ! -d "$EXPORT_DIR" ]; then
  echo "❌ Exportverzeichnis nicht gefunden: $EXPORT_DIR"
  exit 1
fi

# Lade DB-Zugangsdaten aus Zielinstanz
DB_NAME=$(grep DB_NAME "$TARGET_PATH/wp-config.php" | cut -d "'" -f 4)
DB_USER=$(grep DB_USER "$TARGET_PATH/wp-config.php" | cut -d "'" -f 4)
DB_PASS=$(grep DB_PASSWORD "$TARGET_PATH/wp-config.php" | cut -d "'" -f 4)
DB_HOST=$(grep DB_HOST "$TARGET_PATH/wp-config.php" | cut -d "'" -f 4)

echo "📂 Importverzeichnis: $EXPORT_DIR"

# Ordnerstruktur importieren
echo "📄 Importiere Ordnerstruktur..."
TERMS_CSV="$EXPORT_DIR/happyfiles-terms.csv"
if [ -f "$TERMS_CSV" ]; then
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    LOAD DATA LOCAL INFILE '$TERMS_CSV'
    INTO TABLE wp_terms
    FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
    LINES TERMINATED BY '\n'
    (term_id, name, slug);

    INSERT IGNORE INTO wp_term_taxonomy (term_id, taxonomy, description, parent, count)
    SELECT term_id, 'happyfiles_category', '', 0, 0 FROM wp_terms
    WHERE term_id NOT IN (
      SELECT term_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
    );
  "
else
  echo "⚠️ Datei nicht gefunden: happyfiles-terms.csv"
fi

# Term-Metadaten importieren
echo "🔧 Importiere Term-Metadaten..."
METADATA_CSV="$EXPORT_DIR/happyfiles-metadata.csv"
if [ -f "$METADATA_CSV" ]; then
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    DELETE FROM wp_termmeta WHERE term_id IN (
      SELECT term_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
    );

    LOAD DATA LOCAL INFILE '$METADATA_CSV'
    INTO TABLE wp_termmeta
    FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
    LINES TERMINATED BY '\n'
    (meta_id, term_id, meta_key, meta_value);
  "
else
  echo "⚠️ Datei nicht gefunden: happyfiles-metadata.csv"
fi

# Medien-Zuordnungen importieren
echo "🔗 Importiere Medien-Zuordnungen..."
MEDIA_CSV="$EXPORT_DIR/happyfiles-media.csv"
if [ -f "$MEDIA_CSV" ]; then
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    DELETE FROM wp_term_relationships WHERE term_taxonomy_id IN (
      SELECT term_taxonomy_id FROM wp_term_taxonomy WHERE taxonomy = 'happyfiles_category'
    );

    LOAD DATA LOCAL INFILE '$MEDIA_CSV'
    INTO TABLE wp_term_relationships
    FIELDS TERMINATED BY ',' ENCLOSED BY '\"'
    LINES TERMINATED BY '\n'
    (object_id, term_taxonomy_id);
  "
else
  echo "⚠️ Datei nicht gefunden: happyfiles-media.csv"
fi

# Uploads kopieren (von Quelle nach Ziel)
echo "📦 Kopiere Uploads..."
UPLOADS_SOURCE="$EXPORT_DIR/uploads"
if [ -d "$UPLOADS_SOURCE" ]; then
  UPLOADS_TARGET=$(php -r "define('WP_USE_THEMES', false); require('$TARGET_PATH/wp-load.php'); echo wp_get_upload_dir()['basedir'];")
  cp -r "$UPLOADS_SOURCE/." "$UPLOADS_TARGET/" 2>/dev/null || sudo cp -r "$UPLOADS_SOURCE/." "$UPLOADS_TARGET/"
else
  echo "⚠️ Upload-Verzeichnis nicht gefunden!"
fi

echo "✅ Import abgeschlossen!"
