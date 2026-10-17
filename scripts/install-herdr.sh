#!/usr/bin/env bash
# Install or update herdr via cargo / herdr update (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

HERDR_CRATE="${HERDR_CRATE:-herdr}"

ensure_cargo_path

if have_cmd herdr; then
  log "Current herdr: $(command -v herdr)"
  herdr --version 2>/dev/null || true
  log "Updating herdr..."
  herdr update
else
  if ! have_cmd cargo; then
    log "cargo missing; installing first..."
    bash "$ROOT_DIR/scripts/install-cargo.sh"
    ensure_cargo_path
  fi
  log "Installing herdr via cargo..."
  cargo install "$HERDR_CRATE"
fi

ensure_cargo_path
have_cmd herdr || die "herdr not found after install/update"
log "Installed: $(herdr --version)"
log "Active binary: $(command -v herdr)"
log "Done."
