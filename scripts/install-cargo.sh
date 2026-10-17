#!/usr/bin/env bash
# Install rustup + cargo (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

RUSTUP_URL="${RUSTUP_URL:-https://sh.rustup.rs}"
CARGO_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"

ensure_cargo_path

if have_cmd cargo; then
  log "cargo already installed: $(command -v cargo) ($(cargo --version))"
  if have_cmd rustup; then
    log "Updating rustup toolchains..."
    rustup update
  fi
  exit 0
fi

need_cmd curl
log "Installing rustup (cargo)..."
curl --proto '=https' --tlsv1.2 -fsSL "$RUSTUP_URL" | sh -s -- -y --no-modify-path

ensure_cargo_path
have_cmd cargo || die "cargo still not found; add ${CARGO_BIN_DIR} to PATH"
log "Installed: $(cargo --version)"
log "Done."
