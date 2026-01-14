#!/bin/bash

# Name: installiere-vscode-handler.sh
# Zweck: Verknüpft vscode://file/... Links mit "code --goto" auf Linux-Systemen
# Voraussetzung: VS Code ist unter /usr/bin/code installiert

set -e

echo "🛠️ Erstelle Handler-Skript..."

# Skript, das von vscode:// auf 'code --goto' umleitet
sudo tee /usr/local/bin/vscode-handler > /dev/null << 'EOF'
#!/bin/bash

# Entferne das Präfix "vscode://file/"
target="${1#vscode://file/}"

# Trenne Datei und Zeile
file="${target%%:*}"
line="${target##*:}"

# Starte VS Code mit Datei und Zeile
exec code --goto "$file:$line"
EOF

sudo chmod +x /usr/local/bin/vscode-handler

echo "✅ Handler-Skript unter /usr/local/bin/vscode-handler gespeichert."

echo "🖇️ Registriere Desktop-Datei für Protokollhandler..."

# Erstelle lokale Desktop-Datei
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/vscode-handler.desktop << EOF
[Desktop Entry]
Name=VSCode Handler
Exec=/usr/local/bin/vscode-handler %u
Type=Application
NoDisplay=true
MimeType=x-scheme-handler/vscode;
EOF

# Setze den vscode://-Handler systemweit (für den aktuellen Nutzer)
xdg-mime default vscode-handler.desktop x-scheme-handler/vscode

echo "✅ vscode:// ist jetzt mit dem VS Code Handler verknüpft."

# Testausgabe
echo
echo "🧪 Führe einen Test aus..."

cd ~/symfony-guestbook/guestbook-app 2>/dev/null || {
  echo "⚠️ Projektverzeichnis ~/symfony-guestbook/guestbook-app nicht gefunden. Test wird übersprungen."
  exit 0
}

file_path=$(realpath src/Controller/TestController.php)
if [[ -f "$file_path" ]]; then
  echo "📂 Testdatei gefunden: $file_path"
  echo "🚀 Starte Test: Öffne Zeile 14..."
  xdg-open "vscode://file/$file_path:14"
else
  echo "⚠️ TestController.php nicht gefunden. Lege ihn zuerst unter src/Controller/ an."
fi
