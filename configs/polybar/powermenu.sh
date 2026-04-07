#!/bin/bash
# Rofi power menu

LOCK="  Lock"
LOGOUT="  Logout"
SUSPEND="  Suspend"
RESTART="  Restart"
SHUTDOWN="  Shutdown"

CHOICE=$(printf '%s\n' "$LOCK" "$LOGOUT" "$SUSPEND" "$RESTART" "$SHUTDOWN" \
  | rofi -dmenu -i -p "Power" -config ~/.config/rofi/config.rasi)

case "$CHOICE" in
  "$LOCK")     i3lock -c 2e3440 ;;
  "$LOGOUT")   i3-msg exit ;;
  "$SUSPEND")  systemctl suspend ;;
  "$RESTART")  systemctl reboot ;;
  "$SHUTDOWN") systemctl poweroff ;;
esac
