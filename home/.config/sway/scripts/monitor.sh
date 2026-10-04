#!/usr/bin/env bash
# monitor.sh — monitor externo / projetor
#   estender: o externo vira mais área de trabalho, à direita do notebook
#   espelhar: o externo mostra a mesma imagem da tela do notebook (wl-mirror)
#
# Uso: monitor.sh [toggle|estender|espelhar]   (padrão: toggle)
# Ao plugar, o kanshi já deixa estendido; o toggle alterna dali.
set -euo pipefail

INTERNA="eDP-1"
MIRROR_ID="at.yrlf.wl_mirror"

aviso() { notify-send -a monitor -i video-display "Monitor externo" "$1"; }

outputs=$(swaymsg -t get_outputs -r)
ext=$(jq -r --arg i "$INTERNA" '[.[] | select(.name != $i)][0].name // empty' <<<"$outputs")
if [[ -z "$ext" ]]; then
    aviso "Nenhum monitor externo conectado."
    exit 0
fi

modo="${1:-toggle}"
if [[ "$modo" == "toggle" ]]; then
    if pgrep -x wl-mirror >/dev/null; then modo="estender"; else modo="espelhar"; fi
fi

case "$modo" in
    estender)
        pkill -x wl-mirror || true
        largura=$(jq -r --arg i "$INTERNA" '.[] | select(.name == $i) | .rect.width' <<<"$outputs")
        [[ "$largura" =~ ^[0-9]+$ && "$largura" -gt 0 ]] || largura=1920
        swaymsg -q output "$INTERNA" enable pos 0 0
        swaymsg -q output "$ext" enable pos "$largura" 0
        aviso "Estendido: $ext à direita."
        ;;
    espelhar)
        swaymsg -q output "$ext" enable
        pkill -x wl-mirror || true
        wl-mirror --fullscreen-output "$ext" "$INTERNA" >/dev/null 2>&1 &
        disown
        # Garantia: se a janela não abrir em tela cheia no externo sozinha,
        # leva ela pra lá (tenta por até 2 s enquanto o wl-mirror sobe)
        for _ in $(seq 20); do
            sleep 0.1
            if swaymsg -q "[app_id=\"$MIRROR_ID\"] move container to output $ext, fullscreen enable" 2>/dev/null; then
                break
            fi
        done
        swaymsg -q focus output "$INTERNA"
        aviso "Espelhando a tela do notebook em $ext."
        ;;
    *)
        echo "Uso: $(basename "$0") [toggle|estender|espelhar]" >&2
        exit 1
        ;;
esac
