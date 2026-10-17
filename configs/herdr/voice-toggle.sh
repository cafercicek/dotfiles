#!/usr/bin/env bash
# Toggle voice dictation for a language mode.
# Usage: voice-toggle.sh [en|tr]
#   idle      → start recording in that mode
#   recording → stop → transcribe → paste (same as voice-stop.sh)
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/herdr-voice"
PID_FILE="$STATE_DIR/record.pid"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-en}"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    exec "$DIR/voice-stop.sh"
  fi
fi

exec "$DIR/voice-start.sh" "$MODE"
