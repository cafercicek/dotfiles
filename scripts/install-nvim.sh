#!/usr/bin/env bash
# Install Neovim stable tarball to /opt (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NVIM_STABLE_URL="${NVIM_STABLE_URL:-https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz}"
NVIM_INSTALL_PREFIX="${NVIM_INSTALL_PREFIX:-/opt}"
NVIM_DIR_NAME="nvim-linux-x86_64"
NVIM_INSTALL_DIR="${NVIM_INSTALL_PREFIX}/${NVIM_DIR_NAME}"

maybe_sudo() {
  local target="$1"
  shift
  if [[ -w "$(dirname "$target")" ]]; then
    "$@"
  else
    run_as_root "$@"
  fi
}

need_cmd curl
need_cmd tar

if have_cmd nvim; then
  log "Current nvim: $(command -v nvim)"
  nvim --version | head -1
fi

TMP_DIR="$(mktemp -d)"
TARBALL="${TMP_DIR}/${NVIM_DIR_NAME}.tar.gz"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

log "Downloading stable tarball..."
curl -fsSL "$NVIM_STABLE_URL" -o "$TARBALL"

if [[ -d "$NVIM_INSTALL_DIR" ]]; then
  log "Removing old install: ${NVIM_INSTALL_DIR}"
  maybe_sudo "$NVIM_INSTALL_DIR" rm -rf "$NVIM_INSTALL_DIR"
fi

log "Installing to ${NVIM_INSTALL_PREFIX}..."
maybe_sudo "$NVIM_INSTALL_PREFIX" tar xzf "$TARBALL" -C "$NVIM_INSTALL_PREFIX"

NEW_NVIM="${NVIM_INSTALL_DIR}/bin/nvim"
[[ -x "$NEW_NVIM" ]] || die "install failed: ${NEW_NVIM} not found"

log "Installed version:"
"$NEW_NVIM" --version | head -3

ensure_path_prepend "${NVIM_INSTALL_DIR}/bin"
ACTIVE_NVIM="$(command -v nvim 2>/dev/null || true)"
if [[ "$ACTIVE_NVIM" != "${NVIM_INSTALL_DIR}/bin/nvim" ]]; then
  cat <<EOF

note: ensure PATH includes ${NVIM_INSTALL_DIR}/bin (config/bashrc already does).
EOF
fi

log "Done."
