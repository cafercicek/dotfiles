#!/usr/bin/env bash
# alt+e: pane scrollback → clipboard + side nvim (standalone tmux version)
set -euo pipefail

ed="${VISUAL:-${EDITOR:-nvim}}"
f="$(mktemp "${TMPDIR:-/tmp}/tmux-scrollback-XXXXXX.txt")"

tmux capture-pane -p -S -3000 >"$f"

if command -v clip.exe >/dev/null 2>&1; then
  clip.exe <"$f" || true
fi
if command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard <"$f" 2>/dev/null || true
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$f" 2>/dev/null || true
fi

tmux split-window -h -p 45 -c "#{pane_current_path}"
tmux select-pane -T scrollback
sleep 0.15

ed_q="$(printf '%q' "$ed")"
f_q="$(printf '%q' "$f")"
tmux send-keys "$ed_q $f_q; rm -f $f_q" Enter
