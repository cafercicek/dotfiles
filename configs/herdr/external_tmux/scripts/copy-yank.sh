#!/usr/bin/env bash
# Clipboard backend for tmux copy-pipe-and-cancel (WSL/Linux).
if command -v clip.exe >/dev/null 2>&1; then
  clip.exe
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard
else
  cat
fi
