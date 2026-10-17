#!/usr/bin/env bash
# Install zoxide via apt (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd zoxide; then
  log "zoxide already installed: $(command -v zoxide) ($(zoxide --version))"
  exit 0
fi

need_cmd apt-get
log "Installing zoxide..."
run_as_root apt-get update
run_as_root apt-get install -y zoxide

have_cmd zoxide || die "zoxide not found after install"
log "Installed: $(zoxide --version)"
log "Done. (bash hook: eval \"\$(zoxide init bash)\" — already in config/bashrc)"
