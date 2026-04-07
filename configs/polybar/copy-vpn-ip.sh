#!/bin/bash
set -eu

ip=$(ip -4 addr show tun0 2>/dev/null | awk '/inet / {print $2; exit}')

if [ -z "$ip" ]; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "VPN IP" "tun0 is down"
  fi
  exit 0
fi

if command -v xclip >/dev/null 2>&1; then
  printf '%s' "$ip" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  printf '%s' "$ip" | xsel --clipboard --input
else
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "VPN IP" "No clipboard tool installed"
  fi
  exit 1
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "VPN IP copied" "$ip"
fi
