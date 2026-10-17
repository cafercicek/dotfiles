#!/usr/bin/env bash
# Start PulseAudio mic recording for Herdr voice paste pipeline.
# Usage: voice-start.sh [en|tr]
#   en (default, Alt+V): any language → English (Whisper translate)
#   tr (Alt+F): Turkish → Turkish transcript (no translate)
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/herdr-voice"
PID_FILE="$STATE_DIR/record.pid"
TOAST_PID_FILE="$STATE_DIR/toast.pid"
STARTED_FILE="$STATE_DIR/started_at"
MODE_FILE="$STATE_DIR/mode"
RAW_FILE="$STATE_DIR/voice.raw"
PANE_FILE="$STATE_DIR/pane_id"
LABEL_FILE="$STATE_DIR/prev_label"
BIN="${HERDR_BIN_PATH:-herdr}"
CONFIG_ENV="${HERDR_VOICE_ENV:-$HOME/.config/herdr/voice.env}"
META_SOURCE="herdr-voice"

MODE="${1:-en}"
case "$MODE" in
  en|tr) ;;
  *) MODE="en" ;;
esac

if [[ -f "$CONFIG_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_ENV"
  set +a
fi
VOICE_SOURCE="${HERDR_VOICE_SOURCE:-${VOICE_SOURCE:-}}"

notify_left() {
  local title="$1" body="${2:-}"
  "$BIN" notification show "$title" \
    --body "$body" \
    --position bottom-left \
    --sound none >/dev/null 2>&1 || true
}

mode_tag() {
  case "${1:-en}" in
    tr) printf 'TR' ;;
    *)  printf 'EN' ;;
  esac
}

set_rec_badge() {
  local pane="$1" clock="$2" src="$3" mode="${4:-en}"
  local tag label
  tag="$(mode_tag "$mode")"
  label="● REC ${tag} ${clock}"
  # Sidebar label only (no outer window title — that stuck as "REC" on top).
  "$BIN" pane rename "$pane" "$label" >/dev/null 2>&1 || true
  "$BIN" pane report-metadata "$pane" --source "$META_SOURCE" \
    --title "$label" \
    --state-label "unknown=$label" \
    --ttl-ms 3600000 >/dev/null 2>&1 || true
}


stop_badge_loop() {
  if [[ -f "$TOAST_PID_FILE" ]]; then
    local tpid
    tpid="$(cat "$TOAST_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${tpid:-}" ]] && kill -0 "$tpid" 2>/dev/null; then
      kill "$tpid" 2>/dev/null || true
      wait "$tpid" 2>/dev/null || true
    fi
    rm -f "$TOAST_PID_FILE"
  fi
}

mkdir -p "$STATE_DIR"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    # Prefer voice-toggle.sh; if start is hit while live, stop instead.
    exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/voice-stop.sh"
  fi
  rm -f "$PID_FILE"
fi

stop_badge_loop

# Clear a stuck outer title from a previous take (Windows title bar).
python3 <<'PY' >/dev/null 2>&1 || true
import json, socket, os
sock = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")
req = {"id": "voice-title", "method": "client.window_title.clear", "params": {}}
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock)
s.sendall((json.dumps(req) + "\n").encode())
s.recv(4096)
s.close()
PY

pane_id="${HERDR_ACTIVE_PANE_ID:-${HERDR_PANE_ID:-}}"
if [[ -z "$pane_id" ]]; then
  pane_id="$("$BIN" pane current --current 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
fi
printf '%s' "$pane_id" >"$PANE_FILE"
printf '%s' "$MODE" >"$MODE_FILE"
prev_label="$("$BIN" pane get "$pane_id" 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"].get("label") or "")' 2>/dev/null || true)"
if [[ "$prev_label" == ●\ REC* ]]; then
  prev_label=""
fi
printf '%s' "$prev_label" >"$LABEL_FILE"
date +%s >"$STARTED_FILE"

rm -f "$RAW_FILE"

source_args=()
source_label="default"
if [[ -n "${VOICE_SOURCE:-}" ]]; then
  if pactl list short sources 2>/dev/null | awk '{print $2}' | grep -qx -- "$VOICE_SOURCE"; then
    source_args=(--device="$VOICE_SOURCE")
    source_label="$VOICE_SOURCE"
  else
    notify_left "Voice" "Unknown mic: $VOICE_SOURCE — using default"
  fi
elif pactl list short sources 2>/dev/null | awk '{print $2}' | grep -qx RDPSource; then
  source_args=(--device=RDPSource)
  source_label="RDPSource"
fi
printf '%s' "$source_label" >"$STATE_DIR/source"

parec "${source_args[@]}" --format=s16le --rate=16000 --channels=1 --latency-msec=20 "$RAW_FILE" \
  >/dev/null 2>&1 &
echo $! >"$PID_FILE"

tag="$(mode_tag "$MODE")"
if [[ "$MODE" == "tr" ]]; then
  mode_hint="TR transcript (no translate)"
else
  mode_hint="any language → English"
fi

set_rec_badge "$pane_id" "0:00" "$source_label" "$MODE"
notify_left "● REC ${tag} 0:00" "${mode_hint} — same key again to stop"

(
  while [[ -f "$PID_FILE" ]]; do
    rec_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -z "${rec_pid:-}" ]] || ! kill -0 "$rec_pid" 2>/dev/null; then
      break
    fi
    started="$(cat "$STARTED_FILE" 2>/dev/null || date +%s)"
    now="$(date +%s)"
    elapsed=$((now - started))
    mins=$((elapsed / 60))
    secs=$((elapsed % 60))
    printf -v clock '%d:%02d' "$mins" "$secs"
    src="$(cat "$STATE_DIR/source" 2>/dev/null || echo mic)"
    mode="$(cat "$MODE_FILE" 2>/dev/null || echo en)"
    pane="$(cat "$PANE_FILE" 2>/dev/null || true)"
    [[ -n "$pane" ]] && set_rec_badge "$pane" "$clock" "$src" "$mode"
    # Rename/metadata every 5s — 1s spam made Herdr feel laggy.
    sleep 5
  done
) >/dev/null 2>&1 &
echo $! >"$TOAST_PID_FILE"

exit 0
