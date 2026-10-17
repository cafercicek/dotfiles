#!/usr/bin/env bash
# alt+e: copy focused pane scrollback → side pane → nvim with that content.
set -euo pipefail

src="${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID missing}"
bin="${HERDR_BIN_PATH:-herdr}"
ed="${VISUAL:-${EDITOR:-nvim}}"
f="$(mktemp "${TMPDIR:-/tmp}/herdr-scrollback-XXXXXX.txt")"

"$bin" pane read "$src" --source recent >"$f"

# 1) copy all of current pane to clipboard
if command -v clip.exe >/dev/null 2>&1; then
  clip.exe <"$f" || true
fi
if command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard <"$f" 2>/dev/null || true
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$f" 2>/dev/null || true
fi

# 2) side pane with nvim showing the copied content
new="$("$bin" pane split "$src" --direction right --focus --ratio 0.45 \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
"$bin" pane rename "$new" scrollback >/dev/null 2>&1 || true
sleep 0.2

ed_q="$(printf '%q' "$ed")"
f_q="$(printf '%q' "$f")"
"$bin" pane run "$new" bash -lc "$ed_q $f_q; rm -f $f_q"
