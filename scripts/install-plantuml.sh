#!/usr/bin/env bash
# Install PlantUML via apt (pulls a JRE) (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd plantuml; then
  log "plantuml already installed: $(command -v plantuml)"
  plantuml -version 2>/dev/null | head -3 || true
  exit 0
fi

need_cmd apt-get
log "Installing plantuml..."
run_as_root apt-get update
run_as_root apt-get install -y plantuml

have_cmd plantuml || die "plantuml not found after install"
log "Installed: $(command -v plantuml)"
plantuml -version 2>/dev/null | head -3 || true
log "Done. Example: plantuml diagram.puml"
