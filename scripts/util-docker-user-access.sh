#!/usr/bin/env bash
# Ensure $USER is in the docker group (sudo for usermod only).
# Membership is written immediately; this shell still needs re-login / newgrp.
# Usage: just util_docker_user_access
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

need_cmd docker

if id -nG "$USER" 2>/dev/null | grep -qw docker; then
  if docker info >/dev/null 2>&1; then
    log "docker group: OK (no sudo needed in this shell)"
  else
    log "docker group: membership OK — re-login (or: newgrp docker) for this shell"
  fi
  exit 0
fi

log "Adding ${USER} to docker group (needs sudo for usermod)..."
run_as_root usermod -aG docker "$USER"
log "Done. Open a new terminal (or: newgrp docker), then: just status"
