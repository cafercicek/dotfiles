#!/usr/bin/env bash
# Symlink selected configs (backs up existing paths).
# Usage: link-configs.sh [bashrc] [nvim] [herdr] [pi]
# With no args, links all four.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NVIM_SRC="${ROOT_DIR}/configs/nvim"
HERDR_SRC="${ROOT_DIR}/configs/herdr"
PI_SRC="${ROOT_DIR}/configs/pi-agent"
BASHRC_SRC="${ROOT_DIR}/config/bashrc"
LOCAL_EXAMPLE="${ROOT_DIR}/config/bashrc.local.example"

if [[ $# -eq 0 ]]; then
  set -- bashrc nvim herdr pi
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

link_pi() {
  [[ -d "$PI_SRC" && -f "$PI_SRC/settings.json" ]] || die "missing pi agent config at ${PI_SRC}"
  log "Linking pi agent config..."
  # Link each tracked item into ~/.pi/agent (the dir itself stays local:
  # auth.json, sessions/, models-store.json, bin/, install/ are machine state).
  local item name
  shopt -s dotglob nullglob
  for item in "$PI_SRC"/*; do
    name="$(basename "$item")"
    symlink_force "$item" "$HOME/.pi/agent/$name"
  done
  shopt -u dotglob nullglob
}

for name in "$@"; do
  case "$name" in
    bashrc) link_bashrc ;;
    nvim) link_nvim ;;
    herdr) link_herdr ;;
    pi) link_pi ;;
    *) die "unknown config target: ${name} (want: bashrc|nvim|herdr|pi)" ;;
  esac
done

log "Done. Run: exec bash   (or open a new terminal)"
