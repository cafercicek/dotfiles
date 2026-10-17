#!/usr/bin/env bash
# Set global git user.name / user.email (idempotent when already matching).
# Usage: util-git-identity.sh "Full Name" you@example.com
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NAME="${1:-}"
EMAIL="${2:-}"

if [[ -z "$NAME" || -z "$EMAIL" ]]; then
  die "usage: just util_git_identity \"Full Name\" you@example.com"
fi

need_cmd git

cur_name="$(git config --global --get user.name 2>/dev/null || true)"
cur_email="$(git config --global --get user.email 2>/dev/null || true)"

if [[ "$cur_name" == "$NAME" && "$cur_email" == "$EMAIL" ]]; then
  log "git identity already set: ${cur_name} <${cur_email}>"
  exit 0
fi

if [[ -n "$cur_name" || -n "$cur_email" ]]; then
  log "Updating git identity: ${cur_name:-unset} <${cur_email:-unset}> -> ${NAME} <${EMAIL}>"
else
  log "Setting git identity: ${NAME} <${EMAIL}>"
fi

git config --global user.name "$NAME"
git config --global user.email "$EMAIL"

log "Done: $(git config --global --get user.name) <$(git config --global --get user.email)>"
