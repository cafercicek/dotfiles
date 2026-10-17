#!/usr/bin/env bash
# Run installs / config links listed in config/install.config.
# Usage: bootstrap-from-config.sh [apps|configs|all]
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${1:-all}"
CONFIG_FILE="${INSTALL_CONFIG:-${ROOT_DIR}/config/install.config}"
[[ -f "$CONFIG_FILE" ]] || die "missing ${CONFIG_FILE}"

case "$MODE" in
  apps|configs|all) ;;
  *) die "usage: $0 [apps|configs|all]" ;;
esac

run_app() {
  local name="$1"
  local script=""
  case "$name" in
    cargo) script="install-cargo.sh" ;;
    just) script="install-just.sh" ;;
    docker) script="install-docker.sh" ;;
    gh) script="install-gh.sh" ;;
    nvim) script="install-nvim.sh" ;;
    zoxide) script="install-zoxide.sh" ;;
    fzf) script="install-fzf.sh" ;;
    herdr) script="install-herdr.sh" ;;
    cursor-agent) script="install-cursor-agent.sh" ;;
    clangd) script="install-clangd.sh" ;;
    plantuml) script="install-plantuml.sh" ;;
    obsidian) script="install-obsidian.sh" ;;
    udev-xds) script="install-udev-xds.sh" ;;
    usbipd)
      log "Running: just install-usbipd"
      (cd "$ROOT_DIR" && just install-usbipd)
      return 0
      ;;
    *)
      warn "unknown app in install.config: ${name} (skipped)"
      return 0
      ;;
  esac
  log "App: ${name}"
  bash "${ROOT_DIR}/scripts/${script}"
}

collect_section() {
  local want="$1"
  local section=""
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # trim
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      section="${BASH_REMATCH[1]}"
      continue
    fi
    if [[ "$section" == "$want" ]]; then
      printf '%s\n' "$line"
    fi
  done <"$CONFIG_FILE"
}

if [[ "$MODE" == apps || "$MODE" == all ]]; then
  mapfile -t apps < <(collect_section apps)
  if [[ ${#apps[@]} -eq 0 ]]; then
    log "No apps enabled in ${CONFIG_FILE}"
  else
    log "Installing apps from ${CONFIG_FILE}..."
    for app in "${apps[@]}"; do
      run_app "$app"
    done
  fi
fi

if [[ "$MODE" == configs || "$MODE" == all ]]; then
  mapfile -t configs < <(collect_section configs)
  if [[ ${#configs[@]} -eq 0 ]]; then
    log "No configs enabled in ${CONFIG_FILE}"
  else
    log "Linking configs from ${CONFIG_FILE}..."
    bash "${ROOT_DIR}/scripts/link-configs.sh" "${configs[@]}"
  fi
fi

log "Bootstrap (${MODE}) done."
