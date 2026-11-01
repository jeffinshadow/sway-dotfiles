#!/usr/bin/env bash
# Indicador de gravação pro waybar: some quando não está gravando.
# Atualizado pelo sinal 9 (sway/scripts/record.sh) e a cada segundo.
estado="${XDG_RUNTIME_DIR:-/tmp}/gravacao"
pgrep -x wf-recorder >/dev/null && [[ -r $estado ]] || exit 0
{ read -r file; read -r inicio; } < "$estado"
s=$(( $(date +%s) - inicio ))
printf '{"text":"󰑊 %d:%02d","class":"rec","tooltip":"Gravando: %s\\nClique (ou Super+Print): parar"}\n' \
    $(( s / 60 )) $(( s % 60 )) "${file##*/}"
