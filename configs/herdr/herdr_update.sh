#!/usr/bin/env bash
set -euo pipefail

RUSTUP_URL="${RUSTUP_URL:-https://sh.rustup.rs}"
CARGO_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"
HERDR_CRATE="${HERDR_CRATE:-herdr}"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' not found"
}

ensure_path() {
  case ":$PATH:" in
    *":$CARGO_BIN_DIR:"*) ;;
    *) export PATH="$CARGO_BIN_DIR:$PATH" ;;
  esac
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

ensure_cargo() {
  ensure_path
  if command -v cargo >/dev/null 2>&1; then
    log "cargo: $(command -v cargo) ($(cargo --version))"
    return
  fi

  need_cmd curl
  log "cargo not found; installing rustup..."
  curl --proto '=https' --tlsv1.2 -fsSL "$RUSTUP_URL" | sh -s -- -y --no-modify-path
  ensure_path
  command -v cargo >/dev/null 2>&1 || die "cargo still not found after rustup install; add ${CARGO_BIN_DIR} to PATH"
  log "cargo: $(command -v cargo) ($(cargo --version))"
}

ensure_path

if command -v herdr >/dev/null 2>&1; then
  log "Current herdr: $(command -v herdr)"
  herdr --version 2>/dev/null || true
  log "Updating herdr..."
  herdr update
else
  log "No herdr found in PATH; installing via cargo..."
  ensure_cargo
  cargo install "$HERDR_CRATE"
fi

ensure_path
command -v herdr >/dev/null 2>&1 || die "herdr not found after install/update"

log "Installed version:"
herdr --version

ACTIVE_HERDR="$(command -v herdr)"
log "Active binary: ${ACTIVE_HERDR}"
log "Done."
