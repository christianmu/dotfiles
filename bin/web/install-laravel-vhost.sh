#!/bin/bash
# =============================================================================
#  install-laravel-vhost.sh
# =============================================================================
#  Zweck:
#    Installiert eine neue Laravel-App über den Laravel Installer ("laravel new")
#    und richtet einen Apache VirtualHost inkl. /etc/hosts & Berechtigungen ein.
#
#  Highlights:
#    - Keine Prompts dank --no-interaction
#    - Starter-Kit-Auswahl (Livewire / React / Vue / Custom via --using)
#    - Temp-Dir-Install (umgeht "Application already exists!" & --force-Restriktion)
#    - CLI-Xdebug-Warnungen unterdrückt (XDEBUG_MODE=off)
#    - Auto-Frontend-Build (npm install/ci + npm run build) für Starter-Kits
#      -> Build läuft OHNE sudo (damit nvm/PATH des Users greift)
#
#  Ausführung:
#    ./install-laravel-vhost.sh   (als normaler User mit sudo-Rechten)
# =============================================================================

set -euo pipefail

# --- Laufkontext ----------------------------------------------------------------
RUN_AS="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$RUN_AS" | cut -d: -f6)"
COMPOSER_BIN1="$HOME_DIR/.config/composer/vendor/bin"
COMPOSER_BIN2="$HOME_DIR/.composer/vendor/bin"
export PATH="$COMPOSER_BIN1:$COMPOSER_BIN2:$PATH"

if [ "$EUID" -eq 0 ]; then
  echo "⚠️  Bitte NICHT direkt als root ausführen."
  echo "    Starte als normaler Benutzer mit sudo-Rechten, z. B.:"
  echo "      sudo -u <dein-user> ./install-laravel-vhost.sh"
  exit 1
fi

# --- App-Name -------------------------------------------------------------------
echo "Gewünschten Namen für die App eingeben:"
read WEBSITE_NAME

if ! echo "$WEBSITE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
  echo "❌ Ungültiger Name. Nur Buchstaben, Ziffern, - und _ erlaubt."
  exit 1
fi

APP_DIR="/var/www/$WEBSITE_NAME"

# --- Checks ---------------------------------------------------------------------
if ! command -v composer &>/dev/null; then
  echo "❌ Composer ist nicht installiert."
  exit 1
fi
echo "✅ Composer ist installiert."

if ! command -v laravel &>/dev/null; then
  echo "⏬ Installiere Laravel-Installer global für $RUN_AS ..."
  sudo -u "$RUN_AS" composer global require laravel/installer
  export PATH="$COMPOSER_BIN1:$COMPOSER_BIN2:$PATH"
fi
command -v laravel &>/dev/null || { echo "❌ Laravel-Installer nicht gefunden."; exit 1; }
echo "✅ Laravel-Installer gefunden."

if ! dpkg -s apache2 >/dev/null 2>&1; then
  echo "❌ Apache2 ist nicht installiert."
  exit 1
fi
if ! apache2ctl -M 2>/dev/null | grep -q rewrite_module; then
  echo "🔧 Aktiviere mod_rewrite ..."
  sudo a2enmod rewrite >/dev/null
  sudo systemctl reload apache2
fi
echo "✅ Apache bereit."

# --- Zielordner vorbereiten -----------------------------------------------------
echo "📂 Erstelle Laravel-Verzeichnis unter $APP_DIR ..."
sudo mkdir -p "$APP_DIR"
# Für den Build zunächst dem ausführenden User geben
sudo chown -R "$RUN_AS":www-data "$APP_DIR"
sudo chmod -R 775 "$APP_DIR"
echo "✅ Verzeichnis vorbereitet."

# --- Starter-Kit Auswahl --------------------------------------------------------
echo
echo "Starter-Kit auswählen:"
echo "  [0] None (reines Laravel, keine Auth/Frontend-Extras)"
echo "  [1] Livewire Starter Kit (offiziell)"
echo "  [2] React (Inertia) Starter Kit (offiziell)"
echo "  [3] Vue (Inertia) Starter Kit (offiziell)"
echo "  [4] Community/Custom via --using=<org/repo>"
read -p "Auswahl [0-4]: " KIT_CHOICE

USING_ARG=""
case "$KIT_CHOICE" in
  0) echo "➡️ Installation ohne Starter-Kit...";;
  1) USING_ARG="--using=laravel/livewire-starter-kit"; echo "➡️ Livewire Starter Kit...";;
  2) USING_ARG="--using=laravel/react-starter-kit";   echo "➡️ React (Inertia) Starter Kit...";;
  3) USING_ARG="--using=laravel/vue-starter-kit";     echo "➡️ Vue (Inertia) Starter Kit...";;
  4)
     read -p "GitHub Repo im Format org/repo (z.B. devdojo/wave): " CUSTOM_REPO
     [ -z "$CUSTOM_REPO" ] && { echo "❌ Kein Repo angegeben."; exit 1; }
     USING_ARG="--using=$CUSTOM_REPO"
     echo "➡️ Installation via --using=$CUSTOM_REPO ..."
     ;;
  *) echo "❌ Ungültige Auswahl."; exit 1;;
esac

# --- Laravel installieren (Temp-Dir-Flow) --------------------------------------
echo "⏳ Erzeuge neue Laravel-App in $APP_DIR ..."

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# 1) Projekt in Temp erstellen (kein "." als Ziel, kein --force)
pushd "$TMPDIR" >/dev/null
# ohne sudo, aber als RUN_AS? -> nicht nötig, wir sind bereits als RUN_AS unterwegs
# falls Skript via sudo -u RUN_AS gestartet wurde, reicht das. Sonst:
sudo -u "$RUN_AS" env PATH="$PATH" XDEBUG_MODE=off laravel new "$WEBSITE_NAME" --no-interaction $USING_ARG
popd >/dev/null

# 2) Inhalte nach /var/www/<name> kopieren
sudo rsync -a "$TMPDIR/$WEBSITE_NAME"/ "$APP_DIR"/
echo "✅ Laravel-App erstellt."

# --- /etc/hosts -----------------------------------------------------------------
if ! grep -qE "^\s*127\.0\.0\.1\s+$WEBSITE_NAME(\s|$)" /etc/hosts; then
  echo "🛠️ Füge $WEBSITE_NAME zu /etc/hosts hinzu..."
  echo "127.0.0.1   $WEBSITE_NAME" | sudo tee -a /etc/hosts >/dev/null
  echo "✅ Eintrag in /etc/hosts erstellt."
else
  echo "ℹ️ /etc/hosts enthält $WEBSITE_NAME bereits."
fi

# --- Apache VHost --------------------------------------------------------------
VHOST_CONF="/etc/apache2/sites-available/$WEBSITE_NAME.conf"
echo "📝 Erstelle Apache VirtualHost-Konfiguration..."
sudo tee "$VHOST_CONF" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $WEBSITE_NAME
    ServerAlias www.$WEBSITE_NAME
    DocumentRoot $APP_DIR/public

    <Directory $APP_DIR/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$WEBSITE_NAME-access.log combined
</VirtualHost>
EOF
echo "✅ VirtualHost erstellt."

echo "🛠️ Aktiviere Apache VirtualHost..."
sudo a2ensite "$WEBSITE_NAME.conf" >/dev/null
echo "♻️ Lade Apache neu..."
sudo systemctl reload apache2
echo "✅ Apache neu geladen."

# --- .env & App-Key (nur falls nicht bereits gesetzt) --------------------------
if [ ! -f "$APP_DIR/.env" ]; then
  echo "🔧 Erzeuge .env & App-Key..."
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
  chmod 664 "$APP_DIR/.env"
  (cd "$APP_DIR" && XDEBUG_MODE=off php artisan key:generate --no-interaction)
else
  echo "ℹ️ .env bereits vorhanden – Key wurde vermutlich schon gesetzt."
fi

# --- Auto-Frontend-Build für Starter-Kits (OHNE sudo) --------------------------
if [ -n "$USING_ARG" ]; then
  echo "🎨 Starter-Kit erkannt – baue Frontend-Assets..."
  if command -v npm &>/dev/null; then
    echo "📦 npm gefunden (Version: $(npm -v))"
    pushd "$APP_DIR" >/dev/null
    # Reproduzierbare Installation, falls Lockfile vorhanden
    if [ -f package-lock.json ]; then
      npm ci || npm install
    else
      npm install
    fi
    npm run build
    popd >/dev/null
    echo "✅ Frontend-Build abgeschlossen."
  else
    echo "⚠️ npm nicht gefunden – bitte manuell 'npm install && npm run build' im Projekt ausführen."
  fi
fi

# --- Rechte NACH dem Build ------------------------------------------------------
echo "🔒 Setze Berechtigungen..."
sudo chown -R www-data:www-data "$APP_DIR"
sudo chmod -R 775 "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"
# Falls vorhanden, gebaute Assets auch sauber setzen
if [ -d "$APP_DIR/public/build" ]; then
  sudo find "$APP_DIR/public/build" -type d -exec chmod 775 {} \;
  sudo find "$APP_DIR/public/build" -type f -exec chmod 664 {} \;
fi
echo "✅ Berechtigungen gesetzt."

# --- Fertig --------------------------------------------------------------------
echo -e "✅ Einrichtung abgeschlossen. Aufruf im Browser:\n➡️  http://$WEBSITE_NAME"
