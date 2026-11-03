#!/usr/bin/env bash
# cor.sh — conta-gotas: clica num pixel e o hex (#RRGGBB) vai pra área de
# transferência; a notificação mostra uma amostra da cor.
set -uo pipefail
ponto=$(slurp -p) || exit 0   # Esc: sai quieto
hex=$(grim -g "$ponto" -t ppm - | magick - -format '#%[hex:p{0,0}]' info: 2>/dev/null) || exit 1
hex=${hex:0:7}
printf '%s' "$hex" | wl-copy
amostra="${XDG_RUNTIME_DIR:-/tmp}/cor-amostra.png"
magick -size 64x64 "xc:$hex" "$amostra"
rgb=$(printf 'rgb(%d, %d, %d)' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")
notify-send -i "$amostra" "Cor copiada: $hex" "$rgb"
