#!/usr/bin/env bash
# Install Obsidian AppImage under ~/obsidian_local (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OBS_DIR="${OBS_DIR:-$HOME/obsidian_local}"
OBS_LINK="${OBS_DIR}/Obsidian.AppImage"
# Pin when you want a fixed build; empty = latest GitHub release asset.
OBS_VERSION="${OBS_VERSION:-}"

need_cmd curl
need_cmd grep

mkdir -p "$OBS_DIR"

if [[ -z "$OBS_VERSION" ]]; then
  log "Resolving latest Obsidian AppImage..."
  # GitHub releases page lists assets; pick the first amd64/x86_64 AppImage.
  api_json="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)"
  asset_url="$(printf '%s\n' "$api_json" \
    | grep -oE 'https://[^"]+Obsidian-[0-9.]+(-amd64|-x86_64)?\.AppImage' \
    | head -1 || true)"
  [[ -n "$asset_url" ]] || die "could not find Obsidian AppImage in latest release"
  asset_name="$(basename "$asset_url")"
else
  asset_name="Obsidian-${OBS_VERSION}.AppImage"
  asset_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBS_VERSION}/${asset_name}"
fi

target="${OBS_DIR}/${asset_name}"

if [[ -x "$target" && -L "$OBS_LINK" && "$(readlink -f "$OBS_LINK")" == "$(readlink -f "$target")" ]]; then
  log "Obsidian already installed: ${OBS_LINK} -> ${target}"
  exit 0
fi

if [[ ! -x "$target" ]]; then
  log "Downloading ${asset_name}..."
  tmp="$(mktemp "${OBS_DIR}/.obsidian.XXXXXX.AppImage")"
  cleanup() { rm -f "$tmp"; }
  trap cleanup EXIT
  curl -fsSL "$asset_url" -o "$tmp"
  chmod +x "$tmp"
  mv "$tmp" "$target"
  trap - EXIT
fi

ln -sfn "$target" "$OBS_LINK"
log "Linked ${OBS_LINK} -> ${target}"
log "Done. Run: obsidian   (alias in ~/.bashrc.local) or: ${OBS_LINK} --no-sandbox"
