#!/usr/bin/env bash
# Disco da Steam (/mnt/jogos) pro waybar. Sem ele montado não imprime
# nada → o módulo some (latios, ou o disco falhou: fstab usa nofail).
m=/mnt/jogos
mountpoint -q "$m" || exit 0
read -r tam usado livre pct < <(df -h --output=size,used,avail,pcent "$m" | tail -1)
pct=${pct%\%}
class=normal; (( pct >= 90 )) && class=warning
printf '{"text":"󰊗 %s%%","class":"%s","tooltip":"Jogos (%s)\\n%s usados de %s · %s livres"}\n' \
    "$pct" "$class" "$m" "$usado" "$tam" "$livre"
