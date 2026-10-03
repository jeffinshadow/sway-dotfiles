#!/usr/bin/env bash
# Aplica tema/fontes/cursor via gsettings. No Wayland, GTK3/GTK4/libadwaita
# leem daqui (via xdg-desktop-portal-gtk), não do settings.ini.
# Escala de texto por máquina: variável SHADOW_TEXT_SCALE, passada pelo
# arquivo do host (hosts/<hostname>/sway.conf); padrão 1.0.
set -u
gs() { gsettings set org.gnome.desktop.interface "$@"; }

gs color-scheme        'prefer-dark'
gs gtk-theme           'adw-gtk3-dark'
gs icon-theme          'Papirus-Dark'
gs cursor-theme        'Bibata-Modern-Ice'
gs cursor-size         24
gs font-name           'Google Sans 10'
gs document-font-name  'Google Sans 10'
gs monospace-font-name 'Google Sans Code NF 10'
gs font-antialiasing   'rgba'
gs font-hinting        'slight'
gs text-scaling-factor "${SHADOW_TEXT_SCALE:-1.0}"

# Nautilus: terminal padrão pro "Abrir no terminal"
gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true
