#!/usr/bin/env bash
# Histórico da área de transferência (cliphist), estilo Win+V: nwg-clipman
# (janela GTK com busca, prévia de imagem e apagar itens). Escolher um item
# copia; Ctrl+V cola. Sem o nwg-clipman, cai no rofi.
# Liga/desliga: aberto → fecha e sai
if command -v nwg-clipman >/dev/null; then
    pkill -f '[n]wg-clipman' && exit 0
    exec nwg-clipman
fi
pkill -x rofi && exit 0
cliphist list | rofi -dmenu -i -p "Clipboard" -display-columns 2 | cliphist decode | wl-copy
