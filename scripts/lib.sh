#!/usr/bin/env bash
# Shared helpers for startup install scripts.
# shellcheck shell=bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' not found"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif have_cmd sudo; then
    sudo "$@"
  else
    die "root required for: $*"
  fi
}

ensure_path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *":${dir}:"*) ;;
    *) export PATH="${dir}:${PATH}" ;;
  esac
}

ensure_cargo_path() {
  ensure_path_prepend "${CARGO_HOME:-$HOME/.cargo}/bin"
  ensure_path_prepend "$HOME/.local/bin"
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
}

timestamp() {
  date +%Y%m%d%H%M%S
}

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local bak="${path}.bak.$(timestamp)"
    log "Backing up ${path} -> ${bak}"
    mv "$path" "$bak"
  fi
}

symlink_force() {
  local target="$1"
  local link="$2"
  mkdir -p "$(dirname "$link")"
  if [[ -L "$link" ]]; then
    local current
    current="$(readlink -f "$link" 2>/dev/null || true)"
    local want
    want="$(readlink -f "$target" 2>/dev/null || true)"
    if [[ "$current" == "$want" ]]; then
      log "Already linked: ${link} -> ${target}"
      return 0
    fi
  fi
  backup_path "$link"
  ln -s "$target" "$link"
  log "Linked ${link} -> ${target}"
}
