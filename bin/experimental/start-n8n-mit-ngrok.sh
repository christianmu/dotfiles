#!/bin/bash

# 1. .env laden
echo "📄 Lade Umgebungsvariablen aus ~/.n8n/.env ..."
export $(grep -v '^#' ~/.n8n/.env | xargs)

# 2. ngrok starten mit benutzerdefinierter Subdomain
echo "🌐 Starte ngrok mit Subdomain: only-prompt-octopus"
ngrok http --hostname=only-prompt-octopus.ngrok-free.app 5678 > /dev/null &
NGROK_PID=$!

# 3. Warte kurz, bis ngrok aktiv ist
sleep 3

# 4. Starte n8n
echo "🚀 Starte n8n..."
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
N8N_RUNNERS_ENABLED=true \
n8n

# 5. Beende ngrok beim Verlassen von n8n
echo "🛑 Beende ngrok (PID $NGROK_PID)..."
kill $NGROK_PID

