#!/usr/bin/env bash
# Repariert einen /boot-Platzengpass beim Neuerzeugen der initrd.
# Sichert die bestehende initrd, entfernt sie temporär und erzeugt sie neu.
# Nicht während des Vorgangs neu starten.

set -euo pipefail

KERNEL="${1:-$(uname -r)}"
BOOT_DIR="/boot"
BOOT_FILE="${BOOT_DIR}/initrd.img-${KERNEL}"
BACKUP_FILE="/root/initrd.img-${KERNEL}.bak"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ️  $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}" >&2; }

restore_backup() {
	if [[ -f "${BACKUP_FILE}" ]]; then
		warn "Stelle Sicherung wieder her ..."
		sudo cp -a "${BACKUP_FILE}" "${BOOT_FILE}"
		success "Sicherung zurückkopiert: ${BOOT_FILE}"
	else
		error "Keine Sicherung gefunden: ${BACKUP_FILE}"
	fi
}

trap 'error "Skript mit Fehler beendet."; warn "Nicht neu starten, bevor geprüft wurde, ob ${BOOT_FILE} existiert."' ERR

info "Kernel: ${KERNEL}"

if [[ ! -f "${BOOT_FILE}" ]]; then
	error "Datei nicht gefunden: ${BOOT_FILE}"
	exit 1
fi

info "Aktueller Status von /boot:"
df -h "${BOOT_DIR}"
echo

info "Lege Sicherung an:"
echo "   ${BACKUP_FILE}"
sudo cp -a "${BOOT_FILE}" "${BACKUP_FILE}"
success "Sicherung erstellt."

echo
warn "Die aktuelle initrd wird jetzt aus /boot entfernt."
warn "Zwischen Entfernen und erfolgreicher Neuerzeugung NICHT neu starten."
read -rp "Weiter? [j/N] " ANSWER

if [[ ! "${ANSWER}" =~ ^[JjYy]$ ]]; then
	info "Abgebrochen."
	exit 0
fi

echo
info "Entferne alte initrd ..."
sudo rm -f "${BOOT_FILE}"
success "Alte initrd entfernt."

echo
info "Freier Platz auf /boot nach dem Entfernen:"
df -h "${BOOT_DIR}"

echo
info "Erzeuge neue initrd ..."
if sudo update-initramfs -c -k "${KERNEL}"; then
	success "Neue initrd erfolgreich erstellt."
else
	error "Neuerstellung fehlgeschlagen."
	restore_backup
	exit 1
fi

echo
if [[ -f "${BOOT_FILE}" ]]; then
	success "Neue initrd vorhanden: ${BOOT_FILE}"
else
	error "Neue initrd wurde nicht gefunden."
	restore_backup
	exit 1
fi

echo
info "Status von /boot:"
df -h "${BOOT_DIR}"
ls -lh "${BOOT_DIR}"

echo
info "Prüfe Paketstatus ..."
sudo dpkg --configure -a || true
sudo apt -f install || true

echo
success "Fertig."
info "Die Sicherung bleibt erhalten unter:"
echo "   ${BACKUP_FILE}"

