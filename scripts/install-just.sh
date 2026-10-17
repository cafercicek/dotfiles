#!/usr/bin/env bash
# Install just via cargo (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_cargo_path

if ! have_cmd cargo; then
  log "cargo missing; installing first..."
  bash "$ROOT_DIR/scripts/install-cargo.sh"
  ensure_cargo_path
fi

if have_cmd just; then
  log "just already installed: $(command -v just) ($(just --version))"
  log "Updating just via cargo..."
  cargo install just --locked
else
  log "Installing just..."
  cargo install just --locked
fi

ensure_cargo_path
have_cmd just || die "just not found after install"
log "Installed: $(just --version)"
log "Done."
