#!/bin/bash
set -eu

killall -q polybar || true

while pgrep -x polybar >/dev/null; do
  sleep 0.2
done

mkdir -p "$HOME/.config/polybar"

monitor=""
if polybar --list-monitors >/tmp/polybar-monitors.$$ 2>/dev/null; then
  monitor=$(head -n1 /tmp/polybar-monitors.$$ | cut -d: -f1)
fi
rm -f /tmp/polybar-monitors.$$

if [ -n "$monitor" ]; then
  MONITOR="$monitor" polybar main -c "$HOME/.config/polybar/config.ini" >>"$HOME/.config/polybar/polybar.log" 2>&1 &
else
  polybar main -c "$HOME/.config/polybar/config.ini" >>"$HOME/.config/polybar/polybar.log" 2>&1 &
fi
