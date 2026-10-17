#!/usr/bin/env bash
# Install Docker Engine on Debian/Ubuntu (idempotent).
# Package install only (sudo apt). User→docker group: just util_docker_user_access
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd docker && docker compose version >/dev/null 2>&1; then
  log "docker already installed: $(docker --version)"
  docker compose version || true
  log "User access: just util_docker_user_access  (or: just status)"
  exit 0
fi

need_cmd curl
need_cmd apt-get

if [[ ! -f /etc/os-release ]]; then
  die "unsupported OS: /etc/os-release missing"
fi
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}" in
  ubuntu|debian|pop|linuxmint) ;;
  *) die "docker install script targets Debian/Ubuntu; got ID=${ID:-unknown}" ;;
esac

log "Installing Docker Engine (official apt repo)..."
run_as_root apt-get update
run_as_root apt-get install -y ca-certificates curl
run_as_root install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  run_as_root curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
  run_as_root chmod a+r /etc/apt/keyrings/docker.asc
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="${VERSION_CODENAME:-stable}"
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${CODENAME} stable" \
  | run_as_root tee /etc/apt/sources.list.d/docker.list >/dev/null

run_as_root apt-get update
run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

have_cmd docker || die "docker not found after install"
log "Installed: $(docker --version)"
log "Next: just util_docker_user_access  (then re-login / newgrp docker)"
log "Done."
