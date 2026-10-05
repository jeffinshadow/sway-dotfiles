#!/usr/bin/env bash
# GPU AMD (amdgpu): uso, temperatura, VRAM e consumo pro waybar.
# Sem GPU AMD (o latios é Intel) não imprime nada → o módulo some.
for d in /sys/class/drm/card*/device; do
    [[ -r $d/gpu_busy_percent && $(<"$d/vendor") == 0x1002 ]] && break
    d=
done
[[ -n ${d:-} ]] || exit 0

h=$(echo "$d"/hwmon/hwmon*)
uso=$(<"$d/gpu_busy_percent")
temp=$(( $(<"$h/temp1_input") / 1000 ))
vram=$(( $(<"$d/mem_info_vram_used") >> 20 ))
vtot=$(( $(<"$d/mem_info_vram_total") >> 20 ))
watts=$(( $(cat "$h/power1_input" "$h/power1_average" 2>/dev/null | head -1) / 1000000 ))
fan=$(cat "$h/fan1_input" 2>/dev/null || echo "?")

class=normal
(( temp >= 85 )) && class=critical
printf '{"text":"󰢮 %s%%  %s°","class":"%s","tooltip":"GPU %s%%  ·  %s°C\\nVRAM %s / %s MiB\\n%s W  ·  ventoinha %s rpm\\nClique: LACT"}\n' \
    "$uso" "$temp" "$class" "$uso" "$temp" "$vram" "$vtot" "$watts" "$fan"
