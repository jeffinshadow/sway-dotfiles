#!/usr/bin/env bash
# Cloudflare Tunnel pro waybar. Só aparece onde o cloudflared.service está
# habilitado (giratina); fica vermelho se o serviço cair.
systemctl is-enabled -q cloudflared.service 2>/dev/null || exit 0
if systemctl is-active -q cloudflared.service; then
    echo '{"text":"󰒍","class":"normal","tooltip":"Túnel Cloudflare conectado"}'
else
    echo '{"text":"󰒎","class":"critical","tooltip":"Túnel Cloudflare FORA (cloudflared.service parado)"}'
fi
