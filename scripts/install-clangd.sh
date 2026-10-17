#!/usr/bin/env bash
# Install clangd via apt if missing (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd clangd; then
  log "clangd already installed: $(command -v clangd) ($(clangd --version 2>/dev/null | head -1))"
  exit 0
fi

if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  log "clangd not installed; skipping apt install in CI"
  exit 0
fi

need_cmd apt-get
log "clangd not found; installing..."
run_as_root apt-get update
run_as_root apt-get install -y clangd

have_cmd clangd || die "clangd not found after install"
log "Installed: $(clangd --version 2>/dev/null | head -1)"
log "Done."
