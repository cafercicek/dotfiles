#!/usr/bin/env bash
set -euo pipefail
tmux split-window -h -c "#{pane_current_path}"
tmux swap-pane -U
