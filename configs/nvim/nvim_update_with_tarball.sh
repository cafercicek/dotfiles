#!/usr/bin/env bash
set -euo pipefail

NVIM_STABLE_URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
NVIM_INSTALL_PREFIX="${NVIM_INSTALL_PREFIX:-/opt}"
NVIM_DIR_NAME="nvim-linux-x86_64"
NVIM_INSTALL_DIR="${NVIM_INSTALL_PREFIX}/${NVIM_DIR_NAME}"

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

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "root permissions required for ${NVIM_INSTALL_PREFIX}; run with sudo or set NVIM_INSTALL_PREFIX to a writable path (e.g. \$HOME/.local)"
  fi
}

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

TMP_DIR="$(mktemp -d)"
TARBALL="${TMP_DIR}/${NVIM_DIR_NAME}.tar.gz"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if command -v nvim >/dev/null 2>&1; then
  log "Current nvim: $(command -v nvim)"
  nvim --version | head -1
else
  log "No nvim found in PATH"
fi

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

ACTIVE_NVIM="$(command -v nvim 2>/dev/null || true)"
if [[ "$ACTIVE_NVIM" != "${NVIM_INSTALL_DIR}/bin/nvim" ]]; then
  cat <<EOF

note: active 'nvim' is still '${ACTIVE_NVIM:-not found}'.
Add this near the top of ~/.bashrc (before /usr/bin):

  export PATH="${NVIM_INSTALL_DIR}/bin:\$PATH"

Then run: source ~/.bashrc
EOF
fi

log "Done."
