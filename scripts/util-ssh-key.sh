#!/usr/bin/env bash
# Create ~/.ssh/id_ed25519 (ed25519) if missing; always print the public key.
# Usage: util-ssh-key.sh you@example.com
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

EMAIL="${1:-}"
if [[ -z "$EMAIL" ]]; then
  die "usage: just util_ssh_key you@example.com"
fi

need_cmd ssh-keygen

SSH_DIR="${HOME}/.ssh"
KEY="${SSH_DIR}/id_ed25519"
PUB="${KEY}.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$KEY" ]]; then
  log "SSH key already exists: ${KEY}"
else
  log "Generating ed25519 key for ${EMAIL}..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
  chmod 600 "$KEY"
  chmod 644 "$PUB"
  log "Created: ${KEY}"
fi

[[ -f "$PUB" ]] || die "public key missing: ${PUB}"

echo
echo "=== public key (add to GitHub → Settings → SSH keys) ==="
cat "$PUB"
echo "========================================================"
echo "Tip: pbcopy < ${PUB}"
