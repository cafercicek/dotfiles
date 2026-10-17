#!/usr/bin/env bash
# Merge herdr-style tmux bindings into your existing tmux config.
# Usage:
#   apply.sh              # update ~/.tmux.conf (default)
#   apply.sh --reload     # apply + reload running tmux
#   apply.sh --remove     # remove the managed block
#   apply.sh /path/to/.tmux.conf
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$DIR/tmux.conf"
MARKER="# >>> herdr-external-tmux >>>"
END_MARKER="# <<< herdr-external-tmux <<<"
RELOAD=0
REMOVE=0
TARGET="$HOME/.tmux.conf"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reload) RELOAD=1; shift ;;
    --remove) REMOVE=1; shift ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *) TARGET="$1"; shift ;;
  esac
done

TARGET="${TARGET/#\~/$HOME}"
mkdir -p "$(dirname "$TARGET")"

block() {
  cat <<EOF
$MARKER
# Managed by $DIR/apply.sh — do not edit this block by hand.
source-file "$SOURCE"
$END_MARKER
EOF
}

strip_block() {
  awk -v start="$MARKER" -v end="$END_MARKER" '
    $0 == start { skip=1; next }
    $0 == end   { skip=0; next }
    !skip { print }
  ' "$1"
}

if [[ "$REMOVE" -eq 1 ]]; then
  if [[ ! -f "$TARGET" ]]; then
    echo "nothing to remove: $TARGET not found"
    exit 0
  fi
  if ! grep -qF "$MARKER" "$TARGET"; then
    echo "marker not found in $TARGET"
    exit 0
  fi
  tmp="$(mktemp)"
  strip_block "$TARGET" >"$tmp"
  mv "$tmp" "$TARGET"
  echo "removed herdr-external-tmux block from $TARGET"
  exit 0
fi

if [[ -f "$TARGET" ]]; then
  cp "$TARGET" "${TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
  tmp="$(mktemp)"
  if grep -qF "$MARKER" "$TARGET"; then
    strip_block "$TARGET" >"$tmp"
  else
    cat "$TARGET" >"$tmp"
    [[ -s "$tmp" ]] && echo >>"$tmp"
  fi
  block >>"$tmp"
  mv "$tmp" "$TARGET"
else
  {
    echo "# tmux config"
    echo
    block
  } >"$TARGET"
fi

echo "updated $TARGET"
echo "source: $SOURCE"

if [[ "$RELOAD" -eq 1 ]] && tmux info &>/dev/null; then
  tmux source-file "$TARGET"
  echo "reloaded running tmux"
fi
