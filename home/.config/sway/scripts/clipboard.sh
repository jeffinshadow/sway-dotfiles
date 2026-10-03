#!/usr/bin/env bash
# Histórico da área de transferência (cliphist) no rofi
cliphist list | rofi -dmenu -i -p "Clipboard" -display-columns 2 | cliphist decode | wl-copy
