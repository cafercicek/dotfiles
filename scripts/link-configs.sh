#!/usr/bin/env bash
# Symlink selected configs (backs up existing paths).
# Usage: link-configs.sh [bashrc] [nvim] [herdr]
# With no args, links all three.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NVIM_SRC="${ROOT_DIR}/configs/nvim"
HERDR_SRC="${ROOT_DIR}/configs/herdr"
BASHRC_SRC="${ROOT_DIR}/config/bashrc"
LOCAL_EXAMPLE="${ROOT_DIR}/config/bashrc.local.example"

if [[ $# -eq 0 ]]; then
  set -- bashrc nvim herdr
fi

link_bashrc() {
  [[ -f "$BASHRC_SRC" ]] || die "missing ${BASHRC_SRC}"
  log "Linking shell config..."
  symlink_force "$BASHRC_SRC" "$HOME/.bashrc"

  if [[ ! -f "$HOME/.bashrc.local" ]]; then
    if [[ -f "$LOCAL_EXAMPLE" ]]; then
      cp "$LOCAL_EXAMPLE" "$HOME/.bashrc.local"
      log "Created ~/.bashrc.local from example (edit machine-specific paths)"
    fi
  else
    log "~/.bashrc.local already exists (left untouched)"
  fi
}

link_nvim() {
  [[ -d "$NVIM_SRC" && -f "$NVIM_SRC/init.lua" ]] || die "missing nvim config at ${NVIM_SRC}"
  log "Linking nvim config..."
  mkdir -p "$HOME/.config"
  symlink_force "$NVIM_SRC" "$HOME/.config/nvim"
}

link_herdr() {
  [[ -d "$HERDR_SRC" && -f "$HERDR_SRC/config.toml" ]] || die "missing herdr config at ${HERDR_SRC}"
  log "Linking herdr config..."
  mkdir -p "$HOME/.config"
  symlink_force "$HERDR_SRC" "$HOME/.config/herdr"
}

for name in "$@"; do
  case "$name" in
    bashrc) link_bashrc ;;
    nvim) link_nvim ;;
    herdr) link_herdr ;;
    *) die "unknown config target: ${name} (want: bashrc|nvim|herdr)" ;;
  esac
done

log "Done. Run: exec bash   (or open a new terminal)"
