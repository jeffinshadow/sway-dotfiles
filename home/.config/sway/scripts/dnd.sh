#!/usr/bin/env bash
# dnd.sh — liga/desliga o "não perturbe" do mako (modo do-not-disturb do
# mako/config: as notificações ficam guardadas, sem aparecer) e avisa a
# waybar (custom/dnd, sinal 8) pra trocar o ícone na hora.
set -euo pipefail

if makoctl mode | grep -qx do-not-disturb; then
    makoctl mode -r do-not-disturb >/dev/null
    notify-send -a dnd -t 2500 -i notification-active "Não perturbe desligado" \
        "As notificações voltam a aparecer. Super+Shift+. reabre a última."
else
    # Avisa antes de ligar: depois do modo ligado o aviso não apareceria
    notify-send -a dnd -t 2000 -i notification-disabled "Não perturbe ligado" \
        "Notificações escondidas até desligar (Super+Shift+n)."
    sleep 2
    makoctl mode -a do-not-disturb >/dev/null
fi
pkill -RTMIN+8 waybar || true
