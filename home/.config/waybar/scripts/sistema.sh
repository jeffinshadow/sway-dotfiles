#!/usr/bin/env bash
# Pílula "sistema" do waybar: CPU, memória, temperatura, GPU e discos ficam
# no tooltip (ícone + barra + valores). A pílula assume o pior estado deles:
# âmbar (warning) ou vermelho (critical), com o motivo no topo do tooltip.
export LC_ALL=C.UTF-8   # awk com ponto decimal; a vírgula vem depois
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

# GPU AMD (giratina)
gpu=""
for d in /sys/class/drm/card*/device; do
    [[ -r $d/gpu_busy_percent && $(<"$d/vendor") == 0x1002 ]] || continue
    t=$(( $(cat "$d"/hwmon/hwmon*/temp1_input) / 1000 ))
    (( t >= 90 )) && pior 2 "GPU a ${t}°"
    gpu=1; gpu_uso=$(<"$d/gpu_busy_percent"); gpu_temp=$t
    vram=$(awk '{printf "%.1f", $1/1073741824}' "$d/mem_info_vram_used")
    vtot=$(awk '{printf "%.1f", $1/1073741824}' "$d/mem_info_vram_total")
    break
done

# Disco do sistema
d=$(df --output=pcent / | tail -1 | tr -dc 0-9)
(( d >= 95 )) && pior 2 "Disco (/) ${d}% cheio" || { (( d >= 85 )) && pior 1 "Disco (/) ${d}% cheio"; }

# Disco de jogos (giratina): o aviso que era do módulo próprio
if mountpoint -q /mnt/jogos 2>/dev/null; then
    j=$(df --output=pcent /mnt/jogos | tail -1 | tr -dc 0-9)
    (( j >= 90 )) && pior 1 "Disco de jogos ${j}% cheio"
fi

# Memória
read -r m mu mt < <(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2}
    END {printf "%d %.1f %.1f", (t-a)*100/t, (t-a)/1048576, t/1048576}' /proc/meminfo)
(( m >= 95 )) && pior 2 "Memória ${m}%" || { (( m >= 90 )) && pior 1 "Memória ${m}%"; }

# ---- Resumo no tooltip (pango): ícone, nome, barra e valores ----------
# Cores do style.css (Shadow Materia)
AZUL='#8AB8F0'; CINZA='#919093'; TRILHO='#49494B'; AMBAR='#F2DA66'; VERMELHO='#F28B82'
virgula() { echo "${1/./,}"; }
# rep N TEXTO → TEXTO repetido N vezes
rep() { local i out=""; for (( i = 0; i < $1; i++ )); do out+=$2; done; printf '%s' "$out"; }
# barra PCT AVISO CRITICO → 10 células, cor pelo nível
barra() {
    local p=$1 cor=$AZUL cheio=$(( ($1 + 5) / 10 ))
    (( p >= $3 )) && cor=$VERMELHO || { (( p >= $2 )) && cor=$AMBAR; }
    (( cheio > 10 )) && cheio=10
    printf "<span color='%s'>%s</span><span color='%s'>%s</span>" \
        "$cor" "$(rep "$cheio" ━)" "$TRILHO" "$(rep $(( 10 - cheio )) ━)"
}
# linha ÍCONE BARRA TEXTO
linha() { printf "<span color='%s'>%s</span>  %s  %s" "$AZUL" "$1" "$2" "$3"; }

linhas=()
up=$(awk '{d=int($1/86400); h=int($1%86400/3600); m=int($1%3600/60);
    if (d) printf "%dd %dh", d, h; else if (h) printf "%dh %dmin", h, m; else printf "%dmin", m}' /proc/uptime)
linhas+=("<b>$(cut -d- -f2- /etc/hostname)</b>  <span color='$CINZA'>ligada há $up</span>" "")

if (( ${#motivos[@]} )); then
    cor=$AMBAR; (( estado == 2 )) && cor=$VERMELHO
    for m_ in "${motivos[@]}"; do linhas+=("<span color='$cor'>󰀦  $m_</span>"); done
    linhas+=("")
fi

c=${cpu//\?/0}
linhas+=("$(linha 󰻠 "$(barra "$c" 90 101)" "${cpu}%${tcpu:+  ·  ${tcpu}°}")")
linhas+=("$(linha 󰍛 "$(barra "$m" 90 95)" "$(virgula "$mu") / $(virgula "$mt") GiB")")
if [[ -n $gpu ]]; then
    linhas+=("$(linha 󰢮 "$(barra "$gpu_uso" 101 101)" "${gpu_uso}%  ·  ${gpu_temp}°  ·  VRAM $(virgula "$vram") / $(virgula "$vtot") GiB")")
fi
livre=$(df -h --output=avail / | tail -1 | tr -d ' ')
linhas+=("$(linha 󰋊 "$(barra "$d" 85 95)" "${d}%  ·  ${livre/G/ GiB} livres")")
if mountpoint -q /mnt/jogos 2>/dev/null; then
    read -r jp jl < <(df -h --output=pcent,avail /mnt/jogos | tail -1)
    jp=${jp%\%}
    linhas+=("$(linha 󰊗 "$(barra "$jp" 90 101)" "${jp}%  ·  ${jl/G/ GiB} livres")")
fi
linhas+=("" "<span color='$CINZA'>Clique: btop</span>")

classe=(normal warning critical)
tip=$(printf '%s\\n' "${linhas[@]}"); tip=${tip%\\n}
tip=${tip//\"/\\\"}
printf '{"text":"󰨇","class":"%s","tooltip":"<tt>%s</tt>"}\n' "${classe[estado]}" "$tip"
