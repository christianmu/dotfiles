#!/bin/sh

# Präfix und Dateiendungen abfragen
read -p "Gib das Präfix für die neuen Dateinamen ein: " prefix
read -p "Gib die Dateiendung der umzubenennenden Dateien ein (z. B. jpg): " extension
read -p "Gib den Namen des Zielordners ein (wird erstellt, falls nicht vorhanden): " target_folder

# Zielordner erstellen, falls er nicht existiert
mkdir -p "$target_folder"

# Laufende Nummer initialisieren
counter=1

# Dateien kopieren, umbenennen und in den Zielordner verschieben
for file in *."$extension"; do
    # Prüfen, ob Dateien mit der angegebenen Endung existieren
    if [ -f "$file" ]; then
        # Neue Datei mit laufender Nummer erstellen
        new_name="${prefix}_$(printf "%03d" "$counter").${extension}"
        cp "$file" "${target_folder}/${new_name}"
        counter=$((counter + 1))
    fi
done

# Hinweis, falls keine Dateien gefunden wurden
if [ $counter -eq 1 ]; then
    echo "Keine Dateien mit der Endung .$extension gefunden."
else
    echo "Umbenennung abgeschlossen. Dateien wurden in den Ordner '$target_folder' kopiert."
fi

