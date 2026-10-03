#!/usr/bin/env bash
# Espelha o monitor focado em outro (projetor no cliente).
# Abre o wl-mirror em tela cheia; mova a janela pro monitor de destino.
set -euo pipefail
pkill -x wl-mirror && exit 0   # segunda vez = desliga o espelho
src=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
exec wl-mirror "$src"
