#!/bin/bash

# Farben für die Ausgabe
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Funktion zur Fehlerüberprüfung
check_command() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler: Der Befehl '$1' konnte nicht ausgeführt werden.${RESET}"
        exit 1
    fi
}

# Root-Rechte prüfen
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bitte führen Sie dieses Skript mit root-Rechten aus (sudo).${RESET}"
    exit 1
fi

# Schritt 1: Apache und PHP installieren
echo -e "${GREEN}Apache und PHP werden installiert...${RESET}"

# PHP-Version abfragen
echo -e "${GREEN}Welche PHP-Version möchten Sie installieren? (z. B. 8.1, 7.4, 8.2)${RESET}"
read -p "PHP-Version: " php_version

if [ -z "$php_version" ]; then
    echo -e "${RED}Keine PHP-Version angegeben. Das Skript wird beendet.${RESET}"
    exit 1
fi

sudo apt update
check_command "apt update"

sudo apt install -y apache2 software-properties-common
check_command "apt install apache2 und software-properties-common"

# sudo add-apt-repository -y ppa:ondrej/php
# check_command "add-apt-repository ppa:ondrej/php"

sudo apt update
check_command "apt update nach PPA"

sudo apt install -y php$php_version libapache2-mod-php$php_version php$php_version-cli php$php_version-xml php$php_version-mysql
check_command "PHP $php_version und Module installieren"

sudo systemctl start apache2
check_command "Apache starten"

sudo systemctl enable apache2
check_command "Apache für automatischen Start aktivieren"

sudo a2enmod php$php_version
check_command "PHP $php_version Modul aktivieren"

sudo systemctl restart apache2
check_command "Apache neu starten"

# Schritt 2: MariaDB installieren und konfigurieren
echo -e "${GREEN}MariaDB wird installiert...${RESET}"
sudo apt install -y mariadb-server mariadb-client
check_command "mariadb-server und mariadb-client installieren"

echo -e "${GREEN}MariaDB wird konfiguriert...${RESET}"
sudo mysql_secure_installation <<EOF
n
n
y
y
y
y
EOF
check_command "mysql_secure_installation ausführen"

# Schritt 3: Administrativen Benutzer für MariaDB erstellen
echo -e "${GREEN}Administrativen Benutzer für MariaDB erstellen...${RESET}"
echo -e "${GREEN}Bitte geben Sie das Passwort für den Benutzer 'admin' ein:${RESET}"
read -s admin_password

sudo mariadb <<EOF
GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY '${admin_password}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
check_command "Admin-Benutzer erstellen"

# Schritt 4: Status von Apache und MariaDB prüfen
echo -e "${GREEN}Prüfe den Status von Apache und MariaDB...${RESET}"
sudo systemctl status apache2 --no-pager
sudo systemctl status mariadb --no-pager

# Schritt 5: Optional phpinfo()-Testseite erstellen
echo -e "${GREEN}Soll eine phpinfo()-Testseite erstellt werden? (y/n)${RESET}"
read -p "Ihre Auswahl: " create_info
if [ "$create_info" == "y" ]; then
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null
    echo -e "${GREEN}Die Datei info.php wurde unter /var/www/html erstellt.${RESET}"
else
    echo -e "${GREEN}phpinfo()-Testseite wurde nicht erstellt.${RESET}"
fi

# Abschluss
echo -e "${GREEN}Apache, PHP $php_version und MariaDB wurden erfolgreich installiert und konfiguriert.${RESET}"
echo -e "${GREEN}Sie können sich mit 'mysql -u admin -p' in MariaDB einloggen und mit 'http://<server-ip>/info.php' PHP testen.${RESET}"
