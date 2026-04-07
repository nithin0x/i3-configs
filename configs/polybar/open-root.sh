#!/bin/bash
set -eu

if command -v thunar >/dev/null 2>&1; then
  exec thunar /
fi

term=${TERMINAL:-alacritty}
exec "$term" --title "Filesystem" -e bash -lc 'df -h /; printf "\nPress Enter to close..."; read'
