#!/usr/bin/env bash
#
# fix-boot.sh – Kleine Erste Hilfe bei voller /boot-Partition (Pop!_OS / Ubuntu)
# Achtung: auf eigene Gefahr, aber defensiv implementiert.
#

set -u  # undefined vars als Fehler behandeln

# -------- Helferfunktionen --------

die() {
    echo "❌ $*" >&2
    exit 1
}

info() {
    echo "👉 $*"
}

ok() {
    echo "✅ $*"
}

# -------- Root-Check --------

if [[ "$EUID" -ne 0 ]]; then
    die "Bitte als root ausführen (z.B. mit: sudo $0)"
fi

# -------- Aktuellen Kernel ermitteln --------

KVER="$(uname -r)"
BOOT_DEV="$(df -P /boot | awk 'NR==2 {print $1}')"
BOOT_USAGE="$(df -P /boot | awk 'NR==2 {print $5}')"

info "Aktueller Kernel: $KVER"
info "/boot liegt auf: $BOOT_DEV (Belegung: $BOOT_USAGE)"

echo
ls -lh /boot
echo

# -------- Sicherheitsabfrage --------

read -r -p "⚠️  Fortfahren und initramfs für Kernel $KVER neu bauen? [ja/NEIN] " ANSWER
if [[ "${ANSWER,,}" != "ja" ]]; then
    die "Abgebrochen durch Benutzer."
fi

# -------- Alte initrd des aktuellen Kernels entfernen --------

INITRD="/boot/initrd.img-${KVER}"

if [[ -f "$INITRD" ]]; then
    info "Lösche aktuelle Initramfs-Datei: $INITRD"
    rm -f "$INITRD" || die "Konnte $INITRD nicht löschen."
    ok "Initramfs-Datei entfernt. /boot hat jetzt etwas Luft:"
    df -h /boot
else
    info "Keine Initramfs-Datei $INITRD gefunden – überspringe Löschen."
fi

# -------- lz4 installieren (falls nicht vorhanden) --------

if ! command -v lz4 >/dev/null 2>&1; then
    info "lz4 ist nicht installiert – wird nachinstalliert…"
    apt-get update || die "apt-get update fehlgeschlagen."
    apt-get install -y lz4 || die "Installation von lz4 fehlgeschlagen."
    ok "lz4 installiert."
else
    ok "lz4 ist bereits installiert."
fi

# -------- initramfs-Kompression auf LZ4 setzen --------

CONF_DIR="/etc/initramfs-tools/conf.d"
CONF_FILE="${CONF_DIR}/compress"

mkdir -p "$CONF_DIR"

if grep -q '^COMPRESS=' "$CONF_FILE" 2>/dev/null; then
    info "Passe bestehende Kompressions-Einstellung in $CONF_FILE an → COMPRESS=lz4"
    sed -i 's/^COMPRESS=.*/COMPRESS=lz4/' "$CONF_FILE"
else
    info "Setze Kompressions-Einstellung in $CONF_FILE → COMPRESS=lz4"
    echo "COMPRESS=lz4" > "$CONF_FILE"
fi

ok "initramfs wird ab jetzt mit LZ4 komprimiert."

# -------- Neues initramfs für aktuellen Kernel erzeugen --------

info "Erzeuge neues initramfs für Kernel $KVER …"
update-initramfs -c -k "$KVER" || die "update-initramfs ist fehlgeschlagen."

ok "Neues initramfs erzeugt:"
ls -lh /boot/initrd.img-"$KVER"

df -h /boot

# -------- Grub aktualisieren --------

info "Aktualisiere GRUB …"
if command -v update-grub >/dev/null 2>&1; then
    update-grub || die "update-grub fehlgeschlagen."
else
    info "update-grub nicht gefunden (Pop!_OS benutzt ggf. systemd-boot) – überspringe."
fi

# -------- apt/dpkg aufräumen --------

info "Bereinige Paketstatus (dpkg/apt) …"
apt-get --fix-broken install -y || die "apt-get --fix-broken install fehlgeschlagen."
apt-get autoremove --purge -y || info "Nichts zu entfernen."

ok "Fertig. /boot-Status:"
df -h /boot

echo "🎉 /boot wurde bereinigt und initramfs neu erzeugt."

