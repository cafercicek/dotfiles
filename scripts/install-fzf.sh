#!/usr/bin/env bash
# Install fzf via apt (needed for zoxide zi) (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd fzf; then
  log "fzf already installed: $(command -v fzf) ($(fzf --version | head -1))"
  exit 0
fi

need_cmd apt-get
log "Installing fzf..."
run_as_root apt-get update
run_as_root apt-get install -y fzf

have_cmd fzf || die "fzf not found after install"
log "Installed: $(fzf --version | head -1)"
log "Done. (enables: zi interactive directory jump)"
