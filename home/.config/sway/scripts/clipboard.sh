#!/usr/bin/env bash
# Histórico da área de transferência (cliphist) no rofi
# Liga/desliga: rofi aberto (ou travado) → fecha e sai
pkill -x rofi && exit 0

cliphist list | rofi -dmenu -i -p "Clipboard" -display-columns 2 | cliphist decode | wl-copy
