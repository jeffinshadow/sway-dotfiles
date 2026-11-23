#!/usr/bin/env bash
# dnd.sh — liga/desliga o "não perturbe" do SwayNC (as notificações vão pro histórico do painel,
# sem aparecer). O aviso passa por cima do próprio não perturbe (hint SWAYNC_BYPASS_DND).
set -euo pipefail
if [[ "$(swaync-client -D)" == true ]]; then
    swaync-client -df >/dev/null
    notify-send -a dnd -t 2500 -i notification-active "Não perturbe desligado" \
        "As notificações voltam a aparecer. O histórico fica no painel (Super+,)."
else
    swaync-client -dn >/dev/null
    notify-send -a dnd -t 2000 -i notification-disabled -h boolean:SWAYNC_BYPASS_DND:true \
        "Não perturbe ligado" "Notificações vão pro painel sem aparecer (Super+Shift+n desliga)."
fi
