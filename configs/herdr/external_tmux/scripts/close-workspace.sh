#!/usr/bin/env bash
set -euo pipefail
name="$(tmux display-message -p '#S')"
read -r -p "kill session ${name}? (y/n) " ans
[[ "$ans" == y || "$ans" == Y ]] && tmux kill-session
