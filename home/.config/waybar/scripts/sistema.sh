#!/usr/bin/env bash
# Pílula "sistema" do waybar: líder do grupo que esconde CPU, memória,
# temperatura, GPU e disco (abrem ao passar o mouse). Como os módulos ficam
# escondidos, ela herda o pior estado deles: âmbar (warning) ou vermelho
# (critical), com o motivo no tooltip. Limites iguais aos do config.jsonc.
estado=0; motivos=()   # 0 normal, 1 warning, 2 critical
pior() { (( $1 > estado )) && estado=$1; motivos+=("$2"); }

# Temperatura da CPU (coretemp, pacote)
for h in /sys/class/hwmon/hwmon*; do
    [[ $(<"$h/name") == coretemp ]] || continue
    t=$(( $(<"$h/temp1_input") / 1000 ))
    (( t >= 85 )) && pior 2 "CPU a ${t}°"
    break
done

# GPU AMD (giratina): mesma regra do gpu.sh
for d in /sys/class/drm/card*/device; do
    [[ -r $d/gpu_busy_percent && $(<"$d/vendor") == 0x1002 ]] || continue
    t=$(( $(cat "$d"/hwmon/hwmon*/temp1_input) / 1000 ))
    (( t >= 90 )) && pior 2 "GPU a ${t}°"
    break
done

# Disco do sistema
d=$(df --output=pcent / | tail -1 | tr -dc 0-9)
(( d >= 95 )) && pior 2 "Disco (/) ${d}% cheio" || { (( d >= 85 )) && pior 1 "Disco (/) ${d}% cheio"; }

# Memória
m=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo)
(( m >= 95 )) && pior 2 "Memória ${m}%" || { (( m >= 90 )) && pior 1 "Memória ${m}%"; }

classe=(normal warning critical)
if (( ${#motivos[@]} )); then
    tip=$(printf '%s\\n' "${motivos[@]}"); tip=${tip%\\n}
else
    tip="Tudo ok"
fi
printf '{"text":"󰊚","class":"%s","tooltip":"%s\\nPasse o mouse: CPU, memória, temperatura, disco"}\n' \
    "${classe[estado]}" "$tip"
