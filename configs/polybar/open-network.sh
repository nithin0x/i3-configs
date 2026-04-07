#!/bin/bash
set -eu

if command -v nm-connection-editor >/dev/null 2>&1; then
  exec nm-connection-editor
fi

term=${TERMINAL:-alacritty}

if command -v nmtui >/dev/null 2>&1; then
  exec "$term" --title "Network" -e nmtui
fi

exec "$term" --title "Network" -e bash -lc 'ip -br addr; printf "\nPress Enter to close..."; read'
