#!/bin/bash

ip=$(ip -4 addr show tun0 2>/dev/null | awk '/inet / {print $2; exit}')

if [ -n "$ip" ]; then
  printf 'VPN [%s]\n' "$ip"
else
  printf 'VPN [down]\n'
fi
