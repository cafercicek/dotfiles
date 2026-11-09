#!/usr/bin/env bash
# Install pi coding agent via official installer (idempotent, non-interactive).
# Deps: curl, Node.js >= 22.19, npm (ensured here if missing).
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PI_INSTALL_URL="${PI_INSTALL_URL:-https://pi.dev/install.sh}"
PI_NODE_MIN_MAJOR=22
PI_NODE_MIN_MINOR=19
PI_NODE_MIN_PATCH=0
PI_NODE_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/pi-node"

node_version_ok() {
  have_cmd node || return 1
  node -e "
const [maj, min, patch] = process.versions.node.split('.').map(Number);
process.exit(
  maj > ${PI_NODE_MIN_MAJOR} ||
  (maj === ${PI_NODE_MIN_MAJOR} && (min > ${PI_NODE_MIN_MINOR} || (min === ${PI_NODE_MIN_MINOR} && patch >= ${PI_NODE_MIN_PATCH})))
    ? 0 : 1
)
" >/dev/null 2>&1
}

load_standalone_node() {
  local bin="${PI_NODE_BASE}/current/bin"
  [[ -d "$bin" ]] || return 1
  ensure_path_prepend "$bin"
}

ensure_xz() {
  have_cmd xz && return 0
  need_cmd apt-get
  log "Installing xz-utils (needed to extract Node.js)..."
  run_as_root apt-get update
  run_as_root apt-get install -y xz-utils
  have_cmd xz || die "xz still missing after install"
}

install_node_standalone() {
  local platform arch dist_base tmp shasums file dir
  case "$(uname -s)" in
    Linux) platform=linux ;;
    Darwin) platform=darwin ;;
    *) die "unsupported OS for Node.js install: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) die "unsupported arch for Node.js install: $(uname -m)" ;;
  esac

  need_cmd curl
  need_cmd tar
  ensure_xz
  dist_base="https://nodejs.org/dist/latest-v22.x"
  tmp="$(mktemp -d)"
  cleanup_node_tmp() { rm -rf "$tmp"; }
  trap cleanup_node_tmp EXIT

  log "Downloading Node.js ${platform}-${arch} (standalone)..."
  curl -fsSL "${dist_base}/SHASUMS256.txt" -o "${tmp}/SHASUMS256.txt"
  file="$(awk -v suffix="-${platform}-${arch}.tar.xz" '
    index($2, "node-v") == 1 && length($2) >= length(suffix) && substr($2, length($2) - length(suffix) + 1) == suffix { print $2; exit }
  ' "${tmp}/SHASUMS256.txt")"
  [[ -n "$file" ]] || die "no Node.js binary listed for ${platform}-${arch}"

  curl -fsSL "${dist_base}/${file}" -o "${tmp}/${file}"
  awk -v f="$file" '$2 == f { print }' "${tmp}/SHASUMS256.txt" >"${tmp}/SHASUMS256.selected"
  if have_cmd sha256sum; then
    (cd "$tmp" && sha256sum -c SHASUMS256.selected)
  elif have_cmd shasum; then
    (cd "$tmp" && shasum -a 256 -c SHASUMS256.selected)
  fi

  mkdir -p "$PI_NODE_BASE"
  dir="${PI_NODE_BASE}/${file%.tar.xz}"
  rm -rf "$dir"
  tar -xf "${tmp}/${file}" -C "$PI_NODE_BASE"
  rm -f "${PI_NODE_BASE}/current"
  ln -s "$dir" "${PI_NODE_BASE}/current"
  trap - EXIT
  cleanup_node_tmp
  load_standalone_node
  log "Node.js standalone: $(command -v node) ($(node --version))"
}

apt_node_candidate_ok() {
  have_cmd apt-cache || return 1
  local version
  version="$(apt-cache policy nodejs 2>/dev/null | awk '/Candidate:/ { print $2; exit }')"
  [[ -n "$version" && "$version" != "(none)" ]] || return 1
  # Strip epoch / debian revision: 22.19.0-1ubuntu1 → 22.19.0
  version="${version#*:}"
  version="${version%%-*}"
  local major minor patch
  IFS=. read -r major minor patch <<<"$version"
  minor="${minor:-0}"
  patch="${patch:-0}"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ && "$patch" =~ ^[0-9]+$ ]] || return 1
  (( major > PI_NODE_MIN_MAJOR )) && return 0
  (( major == PI_NODE_MIN_MAJOR && minor > PI_NODE_MIN_MINOR )) && return 0
  (( major == PI_NODE_MIN_MAJOR && minor == PI_NODE_MIN_MINOR && patch >= PI_NODE_MIN_PATCH )) && return 0
  return 1
}

ensure_node_npm() {
  load_standalone_node || true
  if node_version_ok && have_cmd npm; then
    log "Node.js OK: $(command -v node) ($(node --version)); npm $(npm --version 2>/dev/null || echo '?')"
    return 0
  fi

  if have_cmd apt-get && apt_node_candidate_ok; then
    log "Installing Node.js + npm via apt..."
    run_as_root apt-get update
    run_as_root apt-get install -y nodejs npm
  else
    log "Apt Node.js too old or unavailable; installing standalone Node 22.x..."
    install_node_standalone
  fi

  load_standalone_node || true
  node_version_ok || die "Node.js ${PI_NODE_MIN_MAJOR}.${PI_NODE_MIN_MINOR}+ required (found: $(node --version 2>/dev/null || echo missing))"
  have_cmd npm || die "npm not found after Node.js install"
  log "Node.js OK: $(command -v node) ($(node --version)); npm $(npm --version)"
}

run_pi_installer() {
  need_cmd curl
  # Official installer prompts on /dev/tty (confirm / start pi). Detach session
  # so bootstrap stays non-interactive and defaults to install/reinstall.
  if have_cmd setsid; then
    log "Running official pi installer (non-interactive)..."
    setsid -w sh -c "curl -fsSL '$PI_INSTALL_URL' | sh" </dev/null
  else
    warn "setsid missing; running installer (may prompt if a TTY is attached)"
    curl -fsSL "$PI_INSTALL_URL" | sh
  fi
}

ensure_path_prepend "$HOME/.local/bin"
ensure_path_prepend "$HOME/.pi/agent/bin"
load_standalone_node || true

if have_cmd pi; then
  log "pi already installed: $(command -v pi) ($(pi --version 2>/dev/null || echo '?'))"
  log "Re-running installer to refresh..."
fi

ensure_node_npm
run_pi_installer

ensure_path_prepend "$HOME/.local/bin"
ensure_path_prepend "$HOME/.pi/agent/bin"
load_standalone_node || true
have_cmd pi || die "pi not found after install; ensure \$HOME/.local/bin is on PATH"
log "Installed: $(pi --version 2>/dev/null || true) ($(command -v pi))"
log "Done. (config: just link / configs pi → ~/.pi/agent/*)"
