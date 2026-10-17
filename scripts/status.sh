#!/usr/bin/env bash
# Report which bootstrap tools are installed.
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_cargo_path
ensure_path_prepend /opt/nvim-linux-x86_64/bin
ensure_path_prepend "$HOME/.local/bin"

check() {
  local name="$1"
  local cmd="$2"
  if have_cmd "$cmd"; then
    local ver
    ver="$("$cmd" --version 2>/dev/null | head -1 || true)"
    printf '  %-14s OK  %s\n' "$name" "${ver:-$(command -v "$cmd")}"
  else
    printf '  %-14s MISSING\n' "$name"
  fi
}

echo "startup tool status"
echo "repo: ${ROOT_DIR}"
echo
check cargo cargo
check rustc rustc
check just just
check docker docker
check gh gh
check nvim nvim
check zoxide zoxide
check fzf fzf
check herdr herdr
check agent agent
check cursor cursor
check clangd clangd
check plantuml plantuml

if [[ -x "${HOME}/obsidian_local/Obsidian.AppImage" ]]; then
  printf '  %-14s OK  %s\n' "obsidian" "${HOME}/obsidian_local/Obsidian.AppImage"
else
  printf '  %-14s MISSING\n' "obsidian"
fi

echo
echo "identity"
git_name="$(git config --global --get user.name 2>/dev/null || true)"
git_email="$(git config --global --get user.email 2>/dev/null || true)"
if [[ -n "$git_name" || -n "$git_email" ]]; then
  printf '  %-14s %s <%s>\n' "git" "${git_name:-unset}" "${git_email:-unset}"
else
  printf '  %-14s MISSING  (just util_git_identity \"Name\" you@example.com)\n' "git"
fi
if [[ -f "${HOME}/.ssh/id_ed25519.pub" ]]; then
  printf '  %-14s OK  %s\n' "ssh" "${HOME}/.ssh/id_ed25519.pub"
else
  printf '  %-14s MISSING  (just util_ssh_key you@example.com)\n' "ssh"
fi

echo
echo "access"
if have_cmd docker; then
  if id -nG "$USER" 2>/dev/null | grep -qw docker; then
    if docker info >/dev/null 2>&1; then
      printf '  %-14s OK  group + no-sudo in this shell\n' "docker"
    else
      printf '  %-14s NEED re-login  (in group; try: newgrp docker)\n' "docker"
    fi
  else
    printf '  %-14s NEED group  (just util_docker_user_access, then re-login)\n' "docker"
  fi
else
  printf '  %-14s MISSING  (just install-docker)\n' "docker"
fi

if have_cmd ssh; then
  # GitHub returns exit 1 even on success; match the greeting instead.
  ssh_out="$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
    -T git@github.com 2>&1 || true)"
  if printf '%s\n' "$ssh_out" | grep -qi 'successfully authenticated'; then
    gh_user="$(printf '%s\n' "$ssh_out" | sed -n 's/.*Hi \([^!]*\)!.*/\1/p' | head -1)"
    printf '  %-14s OK  git@github.com%s\n' "ssh-github" "${gh_user:+ (${gh_user})}"
  elif printf '%s\n' "$ssh_out" | grep -qi 'Permission denied'; then
    printf '  %-14s FAIL  add key: just util_ssh_key you@example.com → GitHub SSH keys\n' "ssh-github"
  else
    printf '  %-14s SKIP  %s\n' "ssh-github" "$(printf '%s' "$ssh_out" | head -1)"
  fi
else
  printf '  %-14s MISSING  (openssh-client)\n' "ssh-github"
fi

echo
echo "configs"
for pair in \
  "bashrc:${HOME}/.bashrc:${ROOT_DIR}/config/bashrc" \
  "nvim:${HOME}/.config/nvim:${ROOT_DIR}/configs/nvim" \
  "herdr:${HOME}/.config/herdr:${ROOT_DIR}/configs/herdr"
do
  IFS=: read -r label link target <<<"$pair"
  if [[ -L "$link" ]]; then
    cur="$(readlink -f "$link" 2>/dev/null || true)"
    want="$(readlink -f "$target" 2>/dev/null || true)"
    if [[ "$cur" == "$want" ]]; then
      printf '  %-14s linked -> %s\n' "$label" "$link"
    else
      printf '  %-14s other link -> %s\n' "$label" "$cur"
    fi
  elif [[ -e "$link" ]]; then
    printf '  %-14s present (not linked to startup)\n' "$label"
  else
    printf '  %-14s missing\n' "$label"
  fi
done

echo
echo "bundled configs"
for mod in nvim herdr; do
  path="${ROOT_DIR}/configs/${mod}"
  if [[ -d "$path" ]]; then
    printf '  %-14s OK  %s\n' "$mod" "$path"
  else
    printf '  %-14s MISSING\n' "$mod"
  fi
done
