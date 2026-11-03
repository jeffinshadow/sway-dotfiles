#!/usr/bin/env bash
# VPN pro waybar: só aparece com alguma VPN do NetworkManager conectada
# (OpenVPN, WireGuard...), com o nome da conexão no tooltip.
command -v nmcli >/dev/null || exit 0
mapfile -t vpns < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | awk -F: '$NF ~ /^(vpn|wireguard)$/ { sub(/:[^:]*$/, ""); print }')
(( ${#vpns[@]} )) || { echo '{"text":""}'; exit 0; }
nomes=$(printf '%s\\n' "${vpns[@]}"); nomes=${nomes%\\n}
printf '{"text":"󰖂","class":"normal","tooltip":"VPN conectada:\\n%s"}\n' "$nomes"
