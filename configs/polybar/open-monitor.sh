#!/bin/bash
set -eu

term=${TERMINAL:-alacritty}

if command -v btop >/dev/null 2>&1; then
  exec "$term" --title "System Monitor" -e btop
elif command -v htop >/dev/null 2>&1; then
  exec "$term" --title "System Monitor" -e htop
else
  exec "$term" --title "System Monitor" -e bash -lc 'top'
fi
