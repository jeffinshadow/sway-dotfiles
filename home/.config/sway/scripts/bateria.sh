#!/usr/bin/env bash
# bateria.sh — avisa com bateria baixa (a barra fica vermelha, mas sem
# olhar pra ela o notebook desligava sem aviso). Sem bateria (giratina) sai.
#   20% → aviso normal · 10% → crítico (fica até dispensar) · 5% → crítico de novo
# Cada nível avisa uma vez por descarga; ligar na tomada zera.
set -u
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[[ -n "$bat" ]] || exit 0

avisado=100
while sleep 60; do
    cap=$(<"$bat/capacity"); st=$(<"$bat/status")
    if [[ "$st" != Discharging ]]; then avisado=100; continue; fi
    for n in 5 10 20; do
        (( cap <= n && n < avisado )) || continue
        avisado=$n
        if (( n == 20 )); then
            notify-send -a bateria -i battery-caution "Bateria em ${cap}%" "Vale ligar na tomada."
        else
            notify-send -a bateria -u critical -i battery-empty "Bateria em ${cap}%!" \
                "Ligue na tomada: o notebook vai desligar em breve."
        fi
        break
    done
done
