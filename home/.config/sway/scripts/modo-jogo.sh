#!/usr/bin/env bash
# modo-jogo.sh — liga/desliga o modo jogo (Super+g):
#  - foco NÃO segue o mouse (o cursor que escorrega pro monitor vertical não rouba o jogo);
#  - não perturbe (alertas críticos continuam aparecendo);
#  - replay buffer dos últimos 60 s (replay.sh; Super+Ctrl+Print salva).
set -euo pipefail
estado="${XDG_RUNTIME_DIR:-/tmp}/modo-jogo"
scripts="$HOME/.config/sway/scripts"

if [[ -e "$estado" ]]; then
    rm -f "$estado"
    swaymsg -q focus_follows_mouse yes
    "$scripts/replay.sh" parar
    makoctl mode -r do-not-disturb >/dev/null || true
    pkill -RTMIN+8 waybar || true
    notify-send -a jogo -t 2500 -i input-gaming "Modo jogo desligado" "Foco segue o mouse e notificações de volta."
else
    notify-send -a jogo -t 2000 -i input-gaming "Modo jogo ligado" \
        "Foco preso, não perturbe e replay (Super+Ctrl+Print salva 60 s)."
    sleep 2                                    # o aviso aparece antes do não perturbe
    touch "$estado"
    swaymsg -q focus_follows_mouse no
    makoctl mode -a do-not-disturb >/dev/null || true
    pkill -RTMIN+8 waybar || true
    "$scripts/replay.sh" iniciar
fi
