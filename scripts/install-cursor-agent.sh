#!/usr/bin/env bash
# Install Cursor CLI / agent (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CURSOR_INSTALL_URL="${CURSOR_INSTALL_URL:-https://cursor.com/install}"

ensure_path_prepend "$HOME/.local/bin"

if have_cmd agent; then
  log "agent already installed: $(command -v agent)"
  agent --version 2>/dev/null | head -3 || true
  log "Re-running official installer to refresh..."
fi

need_cmd curl
log "Installing Cursor agent via official installer..."
curl -fsSL "$CURSOR_INSTALL_URL" | bash

ensure_path_prepend "$HOME/.local/bin"
have_cmd agent || die "agent not found after install; ensure \$HOME/.local/bin is on PATH"
log "agent: $(command -v agent)"
agent --version 2>/dev/null | head -3 || true
if have_cmd cursor; then
  log "cursor: $(command -v cursor)"
fi
log "Done."
