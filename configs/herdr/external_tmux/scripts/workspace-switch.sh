#!/usr/bin/env bash
set -euo pipefail

action="${1:-next}"
current="$(tmux display-message -p '#S' 2>/dev/null || true)"
mapfile -t sessions < <(tmux list-sessions -F '#S' 2>/dev/null | sort || true)

if ((${#sessions[@]} == 0)); then
  tmux new-session -d -s main -c "$HOME"
  sessions=(main)
  current=main
fi

case "$action" in
  new)
    base="ws"
    n=1
    while tmux has-session -t "${base}${n}" 2>/dev/null; do
      ((n++))
    done
    name="${base}${n}"
    tmux new-session -d -s "$name" -c "${PWD:-$HOME}"
    tmux switch-client -t "$name"
    ;;
  prev|next)
    idx=0
    for i in "${!sessions[@]}"; do
      if [[ "${sessions[$i]}" == "$current" ]]; then
        idx=$i
        break
      fi
    done
    if [[ "$action" == next ]]; then
      next_idx=$(((idx + 1) % ${#sessions[@]}))
    else
      next_idx=$(((idx + ${#sessions[@]} - 1) % ${#sessions[@]}))
    fi
    tmux switch-client -t "${sessions[$next_idx]}"
    ;;
  *)
    echo "usage: workspace-switch.sh {prev|next|new}" >&2
    exit 1
    ;;
esac
