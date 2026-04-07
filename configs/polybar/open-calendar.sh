#!/bin/bash
set -eu

term=${TERMINAL:-alacritty}
exec "$term" --title "Calendar" -e bash -lc 'cal -3; printf "\nPress Enter to close..."; read'
