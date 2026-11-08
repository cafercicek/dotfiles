#!/usr/bin/env bash
# Install just via cargo (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_c_compiler() {
  # cargo build scripts need a C linker (cc). Minimal servers often lack it.
  if have_cmd cc || have_cmd gcc || have_cmd clang; then
    return 0
  fi
  need_cmd apt-get
  log "No C compiler (cc); installing build-essential..."
  run_as_root apt-get update
  run_as_root apt-get install -y build-essential
  have_cmd cc || die "cc still missing after installing build-essential"
}

write_just_completion() {
  local dest="${HOME}/.just-completion.bash"
  just --completions bash >"$dest"
  log "Wrote ${dest} (sourced by config/bashrc)"
}

ensure_cargo_path

if ! have_cmd cargo; then
  log "cargo missing; installing first..."
  bash "$ROOT_DIR/scripts/install-cargo.sh"
  ensure_cargo_path
fi

ensure_c_compiler

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
write_just_completion
log "Done."
