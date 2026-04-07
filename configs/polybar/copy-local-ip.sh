#!/bin/bash
set -eu

ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i = 1; i <= NF; ++i) if ($i == "src") {print $(i + 1); exit}}')

if [ -z "$ip" ]; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Local IP" "No active IPv4 address found"
  fi
  exit 0
fi

if command -v xclip >/dev/null 2>&1; then
  printf '%s' "$ip" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  printf '%s' "$ip" | xsel --clipboard --input
else
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Local IP" "No clipboard tool installed"
  fi
  exit 1
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Local IP copied" "$ip"
fi
