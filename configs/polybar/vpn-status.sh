#!/bin/bash
for iface in tun0 wg0 vpn0 tap0; do
  ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
  if [ -n "$ip" ]; then
    echo "%{F#a3be8c}%{T3}%{T-}%{F-}  $ip"
    exit 0
  fi
done
echo "%{F#4c566a}%{T3}%{T-}%{F-}  down"
