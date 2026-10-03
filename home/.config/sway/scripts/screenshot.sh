#!/usr/bin/env bash
# screenshot.sh full|area|window
#   full   → salva a tela focada e copia pro clipboard
#   area   → seleciona área e abre no swappy (anotar/salvar)
#   window → janela focada, salva e copia
set -euo pipefail
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Capturas"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-full}" in
    full)
        out=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
        grim -o "$out" "$file" ;;
    area)
        grim -g "$(slurp)" - | swappy -f -
        exit 0 ;;
    window)
        geom=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
        grim -g "$geom" "$file" ;;
esac
wl-copy < "$file"
notify-send -i "$file" "Captura salva" "$file"
