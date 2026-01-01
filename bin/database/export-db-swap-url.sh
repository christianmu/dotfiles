#!/bin/bash

# Sicherstellen, dass WP-CLI verfügbar ist
if ! command -v wp &> /dev/null
then
    echo "❌ WP-CLI ist nicht installiert oder nicht im PATH verfügbar. Bitte installiere WP-CLI und versuche es erneut."
    exit 1
fi

# Abfrage des WordPress-Pfads
read -p "Dateipfad zur WordPress-Installation deren Datenbank ausgelesen werden soll (/var/www/html/wordpress/...): " wp_path

# Validierung: existiert wp-config.php im angegebenen Pfad?
if [ ! -f "$wp_path/wp-config.php" ]; then
    echo "❌ Keine gültige wp-config.php gefunden unter: $wp_path"
    exit 1
fi

# Eingabe der Ursprungs-URL (z. B. http://localhost)
read -p "Ursprungs-URL (z.B. http://localhost/wordpress/...): " source_url
if [[ -z "$source_url" ]]; then
    echo "❌ Die Ursprungs-URL darf nicht leer sein."
    exit 1
fi

# Eingabe der Ziel-URL (z. B. http://meineseite.com)
read -p "Ziel-URL (z.B. http://meineseite.com): " target_url
if [[ -z "$target_url" ]]; then
    echo "❌ Die Ziel-URL darf nicht leer sein."
    exit 1
fi

# Eingabe des Dateinamens für den Export (z. B. export.sql)
read -p "Dateinamen für den Export (z.B. export.sql): " export_file
if [[ -z "$export_file" ]]; then
    echo "❌ Der Dateiname darf nicht leer sein."
    exit 1
fi

# Optional: Exportverzeichnis festlegen
export_dir="./exports"
mkdir -p "$export_dir"

# WP-CLI-Befehl: führt search-replace im Dump aus und speichert diesen
echo "Exportiere Datenbank mit URL-Ersetzung..."
wp --path="$wp_path" search-replace "$source_url" "$target_url" --all-tables --export="$export_dir/$export_file"

# Erfolgskontrolle
if [ $? -eq 0 ]; then
    echo "✅ Die Datenbank wurde erfolgreich exportiert und als '$export_dir/$export_file' gespeichert."
    echo "🔁 Ersetzt: '$source_url' → '$target_url'"
else
    echo "❌ Ein Fehler ist aufgetreten. Bitte überprüfe deine Eingaben und versuche es erneut."
    exit 1
fi
