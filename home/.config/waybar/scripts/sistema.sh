#!/usr/bin/env bash
# Pílula "sistema" do waybar: líder do grupo que esconde CPU, memória,
# temperatura, GPU e disco (abrem ao passar o mouse). Como os módulos ficam
# escondidos, ela herda o pior estado deles: âmbar (warning) ou vermelho
# (critical), com o motivo no tooltip. Limites iguais aos do config.jsonc.
# O tooltip traz também o resumo de tudo: no monitor da webcam (LG 24") o
# grupo não abre e o resumo fica só aqui (ver config.jsonc).
estado=0; motivos=()   # 0 normal, 1 warning, 2 critical
pior() { (( $1 > estado )) && estado=$1; motivos+=("$2"); }

# Uso da CPU: diferença do /proc/stat desde a última chamada (a cada 5 s)
read -r _ u n s i w q sq st _ < /proc/stat
total=$(( u + n + s + i + w + q + sq + st )); ocioso=$(( i + w ))
cache="${XDG_RUNTIME_DIR:-/tmp}/waybar-sistema-cpu"
cpu="?"
if read -r t0 i0 2>/dev/null < "$cache" && (( total > t0 )); then
    cpu=$(( 100 * ( (total - t0) - (ocioso - i0) ) / (total - t0) ))
fi
echo "$total $ocioso" > "$cache"

# Temperatura da CPU (coretemp, pacote)
tcpu=""
for h in /sys/class/hwmon/hwmon*; do
    [[ $(<"$h/name") == coretemp ]] || continue
    tcpu=$(( $(<"$h/temp1_input") / 1000 ))
    (( tcpu >= 85 )) && pior 2 "CPU a ${tcpu}°"
    break
done

# GPU AMD (giratina): mesma regra do gpu.sh
gpu=""
for d in /sys/class/drm/card*/device; do
    [[ -r $d/gpu_busy_percent && $(<"$d/vendor") == 0x1002 ]] || continue
    t=$(( $(cat "$d"/hwmon/hwmon*/temp1_input) / 1000 ))
    (( t >= 90 )) && pior 2 "GPU a ${t}°"
    gpu="$(<"$d/gpu_busy_percent")%  ·  ${t}°"
    break
done

# Disco do sistema
d=$(df --output=pcent / | tail -1 | tr -dc 0-9)
(( d >= 95 )) && pior 2 "Disco (/) ${d}% cheio" || { (( d >= 85 )) && pior 1 "Disco (/) ${d}% cheio"; }

# Memória
read -r m mu mt < <(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2}
    END {printf "%d %.1f %.1f", (t-a)*100/t, (t-a)/1048576, t/1048576}' /proc/meminfo)
(( m >= 95 )) && pior 2 "Memória ${m}%" || { (( m >= 90 )) && pior 1 "Memória ${m}%"; }

# Resumo (vírgula decimal, como no resto da barra em pt_BR)
linhas=("CPU      ${cpu}%${tcpu:+  ·  ${tcpu}°}"
        "Memória  ${mu/./,} / ${mt/./,} GiB  (${m}%)")
[[ -n $gpu ]] && linhas+=("GPU      $gpu")
linhas+=("Disco    ${d}%  (/)")

classe=(normal warning critical)
(( ${#motivos[@]} )) && linhas=("${motivos[@]}" "" "${linhas[@]}")
tip=$(printf '%s\\n' "${linhas[@]}" "" "Clique: btop"); tip=${tip%\\n}
printf '{"text":"󰊚","class":"%s","tooltip":"<tt>%s</tt>"}\n' "${classe[estado]}" "$tip"
