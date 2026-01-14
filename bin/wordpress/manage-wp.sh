#!/bin/bash

# Verzeichnisse durchsuchen
BASE_DIR="/var/www"
WP_FOLDERS=($(find "$BASE_DIR" -maxdepth 1 -type d))

# Farben definieren
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"  # No Color

# Funktion zur Verwaltung einer Installation
manage_installation() {
    local INSTALL_NAME=$1
    local INSTALL_PATH="$BASE_DIR/$INSTALL_NAME"
    local CONFIG_FILE="$INSTALL_PATH/wp-config.php"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Fehler: Keine wp-config.php gefunden unter $INSTALL_PATH${NC}"
        exit 1
    fi

    # Datenbankdaten aus wp-config.php extrahieren
    local DB_NAME=$(grep -oP "(?<=define\('DB_NAME', ').*(?='\);)" "$CONFIG_FILE")
    local DB_USER=$(grep -oP "(?<=define\('DB_USER', ').*(?='\);)" "$CONFIG_FILE")
    local DB_PASS=$(grep -oP "(?<=define\('DB_PASSWORD', ').*(?='\);)" "$CONFIG_FILE")

    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
        echo -e "${RED}❌ Datenbankinformationen konnten nicht aus wp-config.php gelesen werden.${NC}"
        exit 1
    fi

    echo -e "\n${YELLOW}🔧 Verwaltung der Installation: $INSTALL_NAME${NC}"
    echo "1) WordPress URL aktualisieren (auf localhost)"
    echo "2) Permalinks aktualisieren"
    echo "3) wp-config.php anzeigen"
    echo "4) Zurück zum Hauptmenü"
    echo "5) Beenden"

    read -p "Wähle eine Option: " OPTION

    case $OPTION in
        1)
            echo -e "${YELLOW}🔄 Aktualisiere WordPress-URL in der Datenbank...${NC}"
            mysql -u"$DB_USER" -p"$DB_PASS" -e "
            USE $DB_NAME;
            UPDATE wp_options SET option_value = 'http://localhost/wordpress/$INSTALL_NAME' WHERE option_name = 'siteurl';
            UPDATE wp_options SET option_value = 'http://localhost/wordpress/$INSTALL_NAME' WHERE option_name = 'home';
            " 2>/tmp/mysql_error.log

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ WordPress-URLs wurden erfolgreich aktualisiert.${NC}"
            else
                echo -e "${RED}❌ Fehler beim Aktualisieren der Datenbank. Siehe /tmp/mysql_error.log.${NC}"
                cat /tmp/mysql_error.log
            fi
            ;;
        
        2)
            echo -e "${YELLOW}🔄 Aktualisiere Permalinks durch Aufruf von wp-cli...${NC}"
            if command -v wp &> /dev/null; then
                cd "$INSTALL_PATH"
                wp rewrite flush --allow-root
                echo -e "${GREEN}✅ Permalinks erfolgreich aktualisiert.${NC}"
            else
                echo -e "${RED}❌ wp-cli ist nicht installiert. Installiere es mit 'sudo apt install wp-cli'.${NC}"
            fi
            ;;
        
        3)
            echo -e "${YELLOW}📄 Anzeige der wp-config.php von $INSTALL_NAME...${NC}"
            cat "$CONFIG_FILE"
            ;;
        
        4)
            echo -e "${YELLOW}↩️  Zurück zum Hauptmenü${NC}"
            main_menu
            ;;
        
        5)
            echo -e "${GREEN}✅ Programm beendet.${NC}"
            exit 0
            ;;
        
        *)
            echo -e "${RED}❌ Ungültige Auswahl. Bitte erneut versuchen.${NC}"
            manage_installation "$INSTALL_NAME"
            ;;
    esac
}

# Hauptmenü-Funktion
main_menu() {
    # Ausgabe vorbereiten
    echo -e "\n🔍 Gefundene WordPress-Installationen:"
    echo "-------------------------------------"

    local FOUND=false

    for DIR in "${WP_FOLDERS[@]}"; do
        if [ -f "$DIR/wp-config.php" ]; then
            FOLDER_NAME=$(basename "$DIR")
            printf "✅ ${GREEN}%s${NC} - Gefunden unter: %s\n" "$FOLDER_NAME" "$DIR"
            FOUND=true
        fi
    done

    if [ "$FOUND" = false ]; then
        echo -e "${RED}❌ Keine WordPress-Installationen gefunden.${NC}"
        exit 1
    fi

    echo "-------------------------------------"

    # Benutzereingabe
    echo -e "\nGib den Namen der Installation ein, die du verwalten möchtest (oder 'exit' zum Beenden):"
    read INSTALL_NAME

    if [ "$INSTALL_NAME" == "exit" ]; then
        echo -e "${GREEN}✅ Programm beendet.${NC}"
        exit 0
    fi

    manage_installation "$INSTALL_NAME"
}

# Starte das Hauptmenü
main_menu
