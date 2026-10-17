#!/usr/bin/env bash
# Stop recording → Whisper.cpp (CPU) → paste into target pane.
# Mode comes from voice-start: en (translate→EN) or tr (keep Turkish).
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/herdr-voice"
PID_FILE="$STATE_DIR/record.pid"
TOAST_PID_FILE="$STATE_DIR/toast.pid"
RAW_FILE="$STATE_DIR/voice.raw"
WAV_FILE="$STATE_DIR/voice.wav"
PANE_FILE="$STATE_DIR/pane_id"
TXT_FILE="$STATE_DIR/voice.txt"
MODE_FILE="$STATE_DIR/mode"
LABEL_FILE="$STATE_DIR/prev_label"
BIN="${HERDR_BIN_PATH:-herdr}"
META_SOURCE="herdr-voice"
CONFIG_ENV="${HERDR_VOICE_ENV:-$HOME/.config/herdr/voice.env}"
if [[ -f "$CONFIG_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_ENV"
  set +a
fi

WHISPER_DIR="${HERDR_WHISPER_DIR:-$HOME/.local/opt/whisper.cpp/whisper-bin-ubuntu-x64}"
WHISPER_BIN="${HERDR_WHISPER_BIN:-$WHISPER_DIR/whisper-cli}"
MODEL="${HERDR_WHISPER_MODEL:-$HOME/.local/opt/whisper.cpp/models/ggml-small.bin}"

notify() {
  local title="$1" body="${2:-}" sound="${3:-none}"
  "$BIN" notification show "$title" \
    --body "$body" \
    --position bottom-left \
    --sound "$sound" >/dev/null 2>&1 || true
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

clear_rec_badge() {
  local pane="${1:-}"
  local prev=""
  if [[ -n "$pane" ]]; then
    "$BIN" pane report-metadata "$pane" --source "$META_SOURCE" \
      --clear-title --clear-state-labels --ttl-ms 1 >/dev/null 2>&1 || true
    prev="$(cat "$LABEL_FILE" 2>/dev/null || true)"
    if [[ -n "$prev" ]]; then
      "$BIN" pane rename "$pane" "$prev" >/dev/null 2>&1 || true
    else
      "$BIN" pane rename "$pane" --clear >/dev/null 2>&1 || true
    fi
  fi
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
}

VAD_PY="${HERDR_VOICE_VAD:-$HOME/.config/herdr/voice-vad.py}"

if [[ ! -f "$PID_FILE" ]]; then
  notify "Voice" "Not recording (Alt+V / Alt+F to toggle)"
  exit 0
fi

pane_id="$(cat "$PANE_FILE" 2>/dev/null || true)"
if [[ -z "${pane_id:-}" ]]; then
  pane_id="${HERDR_ACTIVE_PANE_ID:-${HERDR_PANE_ID:-}}"
fi
if [[ -z "${pane_id:-}" ]]; then
  pane_id="$("$BIN" pane current --current 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
fi

MODE="$(cat "$MODE_FILE" 2>/dev/null || echo en)"
case "$MODE" in
  tr) lang_label="TR" ;;
  *)  MODE="en"; lang_label="EN" ;;
esac

stop_badge_loop
clear_rec_badge "$pane_id"
notify "● Voice" "Recording ended — transcribing…"

rec_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [[ -n "${rec_pid:-}" ]] && kill -0 "$rec_pid" 2>/dev/null; then
  kill "$rec_pid" 2>/dev/null || true
  wait "$rec_pid" 2>/dev/null || true
fi
rm -f "$PID_FILE"

if [[ ! -s "$RAW_FILE" ]]; then
  notify "Voice" "No audio captured"
  exit 1
fi

bytes="$(wc -c <"$RAW_FILE" | tr -d ' ')"
if (( bytes < 8000 )); then
  notify "Voice" "Recording too short / silent"
  exit 1
fi

# VAD: skip Whisper on near-silence (avoids "Thanks for watching" / "you").
duration_seconds="$(python3 -c "print($bytes / 32000)")"
if [[ -f "$VAD_PY" ]]; then
  if ! python3 "$VAD_PY" check-raw "$RAW_FILE" >/dev/null; then
    notify "Voice" "No speech detected — nothing pasted"
    exit 0
  fi
fi

if [[ ! -x "$WHISPER_BIN" ]]; then
  notify "Voice" "whisper-cli missing: $WHISPER_BIN"
  exit 1
fi
if [[ ! -f "$MODEL" ]]; then
  notify "Voice" "Model missing: $MODEL"
  exit 1
fi

notify "● Voice" "Whisper ${lang_label}…"

python3 - "$RAW_FILE" "$WAV_FILE" <<'PY'
import sys, wave
raw_path, wav_path = sys.argv[1], sys.argv[2]
with open(raw_path, "rb") as f:
    data = f.read()
with wave.open(wav_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(16000)
    w.writeframes(data)
PY

rm -f "$TXT_FILE" "${WAV_FILE}.txt"
# Prefer this install's libs first (avoids mixing CPU prebuilt .so with CUDA build).
export LD_LIBRARY_PATH="$WHISPER_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# -ng: CPU only (0 VRAM)
# en: auto-detect + translate → English
# tr: force Turkish, no translate
# HERDR_WHISPER_USE_GPU=1 → CUDA/VRAM; otherwise -ng keeps VRAM free.
whisper_args=(-m "$MODEL" -f "$WAV_FILE" -nt -np -otxt -of "${TXT_FILE%.txt}")
if [[ "${HERDR_WHISPER_USE_GPU:-0}" == "1" ]]; then
  : # GPU path (omit -ng)
else
  whisper_args+=(-ng)
fi
if [[ "$MODE" == "tr" ]]; then
  whisper_args+=(-l tr)
else
  whisper_args+=(-l auto -tr)
fi

"$WHISPER_BIN" "${whisper_args[@]}" >/dev/null 2>&1 || {
  notify "Voice" "Whisper failed"
  exit 1
}

text="$(python3 - "$TXT_FILE" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
t = p.read_text(encoding="utf-8", errors="replace").strip()
t = " ".join(t.split())
print(t, end="")
PY
)"

if [[ -z "$text" ]]; then
  notify "Voice" "Empty transcript"
  exit 1
fi

# Drop short-clip stock hallucinations Whisper invents for noise.
if [[ -f "$VAD_PY" ]]; then
  if ! printf '%s' "$text" | python3 "$VAD_PY" check-text "$duration_seconds" >/dev/null; then
    notify "Voice" "Ignored junk transcript: $text"
    exit 0
  fi
fi

"$BIN" pane send-text "$pane_id" "$text" >/dev/null

if command -v clip.exe >/dev/null 2>&1; then
  printf '%s' "$text" | clip.exe >/dev/null 2>&1 || true
fi

preview="$text"
if ((${#preview} > 120)); then
  preview="${preview:0:117}..."
fi
notify "● Voice" "Pasted (${lang_label}): $preview" done
exit 0
