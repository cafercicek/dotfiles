#!/usr/bin/env bash
# Install GitHub CLI (gh) via official apt repo (idempotent).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if have_cmd gh; then
  log "gh already installed: $(command -v gh) ($(gh --version | head -1))"
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
  *) die "gh install script targets Debian/Ubuntu; got ID=${ID:-unknown}" ;;
esac

log "Installing GitHub CLI (official apt repo)..."
run_as_root apt-get update
run_as_root apt-get install -y ca-certificates curl
run_as_root install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]]; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | run_as_root tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  run_as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
fi

ARCH="$(dpkg --print-architecture)"
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | run_as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null

run_as_root apt-get update
run_as_root apt-get install -y gh

have_cmd gh || die "gh not found after install"
log "Installed: $(gh --version | head -1)"
log "Done. Login with: just util_gh_login ghp_xxxx"
