#!/usr/bin/env bash
# externo-modo.sh — modo do monitor externo no notebook (chamado pelo kanshi)
#   aceita 1920x1080 perto de 60 Hz → usa esse modo (uso geral)
#   não aceita (projetor antigo, TV 720p...) → maior resolução com pelo menos
#   50 Hz (evita 4K a 30 Hz pelo HDMI 1.4); sem nenhuma, a maior que houver.
# Escala sempre 1.0. A tela interna (eDP-1) não é tocada.
# O sway não informa qual modo é o "preferido" do EDID, daí a escolha acima.
set -euo pipefail

INTERNA="eDP-1"

swaymsg -t get_outputs -r | jq -r --arg i "$INTERNA" '
    def hz: "\(.width)x\(.height)@\(.refresh / 1000 * 1000 | floor / 1000)Hz";
    .[] | select(.name != $i and .active) |
    ( [ .modes[] | select(.width == 1920 and .height == 1080
                           and .refresh >= 59000 and .refresh <= 61000) ]
      | sort_by((.refresh - 60000) | fabs) | first ) as $fhd |
    ( [ .modes[] | select(.refresh >= 50000) ] | max_by([.width * .height, .refresh]) ) as $bom |
    ( .modes | max_by([.width * .height, .refresh]) ) as $maior |
    if $fhd then [.name, ($fhd | hz), "1080p"]
    else [.name, (($bom // $maior) | hz), "fallback"] end
    | @tsv' |
while IFS=$'\t' read -r nome modo tipo; do
    swaymsg -q output "$nome" mode "$modo" scale 1.0
    if [[ "$tipo" == "fallback" ]]; then
        notify-send -a monitor -i video-display "Monitor externo" \
            "$nome não aceita 1080p 60 Hz: usando ${modo%@*}."
    fi
done
