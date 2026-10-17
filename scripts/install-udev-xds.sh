#!/usr/bin/env bash
# Install udev symlink rules for TI XDS110 (multi-MCU) USB serial.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

RULES_FILE="/etc/udev/rules.d/99-xds.rules"
RULE='SUBSYSTEM=="usb", ATTRS{idVendor}=="0451", ATTRS{idProduct}=="bef3", SYMLINK+="xds_uart_%n"'

if [[ -f "$RULES_FILE" ]] && grep -Fq 'idProduct}=="bef3"' "$RULES_FILE" 2>/dev/null; then
  log "udev rule already present: ${RULES_FILE}"
else
  log "Writing ${RULES_FILE}..."
  printf '%s\n' "$RULE" | run_as_root tee "$RULES_FILE" >/dev/null
fi

log "Reloading udev rules..."
run_as_root udevadm control --reload
if have_cmd udevadm; then
  run_as_root udevadm trigger --subsystem-match=usb || true
fi

log "Done. After attaching XDS110 (just util_usbipd …), look for /dev/xds_uart_*"
