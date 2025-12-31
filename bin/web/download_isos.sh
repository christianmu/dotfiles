#!/bin/bash
# ISO-Downloader für Ventoy-Stick
# Erstellt von Chris + ChatGPT 😊

VENTOY_MOUNT="/media/$USER/Ventoy"

# Prüfen, ob Ventoy eingehängt ist
if [ ! -d "$VENTOY_MOUNT" ]; then
  echo "❌ Ventoy-Stick ist nicht eingehängt unter $VENTOY_MOUNT"
  exit 1
fi

echo "✅ Ventoy gefunden: $VENTOY_MOUNT"

# Ordnerstruktur anlegen
mkdir -p "$VENTOY_MOUNT/rescue"
mkdir -p "$VENTOY_MOUNT/linux"

# Download-Links
CLONEZILLA="https://downloads.sourceforge.net/project/clonezilla/clonezilla_live_stable/3.2.2-15/clonezilla-live-3.2.2-15-amd64.iso"
GPARTED="https://downloads.sourceforge.net/gparted/gparted-live-1.7.0-8-amd64.iso"
SYSTEMRESCUE="https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/11.01/systemrescue-11.01-amd64.iso/download"
RESCATUX="https://downloads.sourceforge.net/project/rescatux/rescatux-0.74/rescatux-0.74.iso"
MEMTEST="https://www.memtest.org/download/6.20/memtest86+-6.20.iso.zip"
POPOS="https://pop-iso.sfo2.cdn.digitaloceanspaces.com/22.04/amd64/intel/58/pop-os_22.04_amd64_intel_58.iso"

# Arrays mit Zielordnern
declare -A ISOS=(
  ["$VENTOY_MOUNT/rescue/clonezilla.iso"]=$CLONEZILLA
  ["$VENTOY_MOUNT/rescue/gparted.iso"]=$GPARTED
  ["$VENTOY_MOUNT/rescue/systemrescue.iso"]=$SYSTEMRESCUE
  ["$VENTOY_MOUNT/rescue/rescatux.iso"]=$RESCATUX
  ["$VENTOY_MOUNT/linux/popos.iso"]=$POPOS
)

# Normale ISOs herunterladen
for TARGET in "${!ISOS[@]}"; do
  URL=${ISOS[$TARGET]}
  NAME=$(basename "$TARGET")
  echo "⬇️  Lade $NAME herunter ..."
  wget -O "/tmp/$NAME" "$URL"
  if [ $? -eq 0 ]; then
    echo "📦 Kopiere $NAME nach $TARGET ..."
    cp "/tmp/$NAME" "$TARGET"
  else
    echo "⚠️ Fehler beim Herunterladen von $NAME"
  fi
done

# Memtest86+ separat behandeln
echo "⬇️  Lade Memtest86+ herunter ..."
wget -O "/tmp/memtest.zip" "$MEMTEST"
if [ $? -eq 0 ]; then
  echo "📂 Entpacke Memtest86+ ..."
  unzip -j "/tmp/memtest.zip" "*.iso" -d "/tmp/"
  MEMTEST_ISO=$(ls /tmp/memtest86+*.iso 2>/dev/null | head -n 1)
  if [ -n "$MEMTEST_ISO" ]; then
    echo "📦 Kopiere $(basename "$MEMTEST_ISO") nach Ventoy/rescue ..."
    cp "$MEMTEST_ISO" "$VENTOY_MOUNT/rescue/memtest86+.iso"
  else
    echo "⚠️ Konnte keine ISO in memtest.zip finden!"
  fi
else
  echo "⚠️ Fehler beim Herunterladen von Memtest86+"
fi

# README auf den Stick legen
cat << 'EOF' > "$VENTOY_MOUNT/README.txt"
====================================
 Ventoy Multiboot Stick – Übersicht
====================================

Dieser Stick enthält mehrere Rettungs- und Installations-ISOs.
Im Ventoy-Menü kannst du beim Booten direkt auswählen.

Ordnerstruktur:

/rescue
  Clonezilla   -> Backup & Klonen kompletter Festplatten
  GParted Live -> Partitionieren, Größen ändern, reparieren
  SystemRescue -> Allround-Rettungssystem mit vielen Tools
  Rescatux     -> Bootloader- und Passwort-Reparatur
  Memtest86+   -> Arbeitsspeicher-Testprogramm

/linux
  Pop!_OS      -> Vollwertiges Linux (Live + Installer)

====================================
Hinweis:
- Neue ISOs einfach in einen Ordner kopieren.
- Ventoy erkennt automatisch alle bootfähigen ISOs.
- Diese README dient nur als Übersicht.
====================================
EOF

echo "✅ Fertig! ISOs + README liegen jetzt sortiert auf $VENTOY_MOUNT"

