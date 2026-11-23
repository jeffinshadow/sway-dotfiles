#!/usr/bin/env bash
# Estado do modo jogo pro waybar (atualizado pelo sinal 10, que o sway/scripts/modo-jogo.sh
# manda ao ligar/desligar). Clique alterna (modo-jogo.sh).
estado="${XDG_RUNTIME_DIR:-/tmp}/modo-jogo"
if [[ -e "$estado" ]]; then
    origem=$(cat "$estado" 2>/dev/null)
    [[ "$origem" == auto ]] && quem="ligado sozinho (jogo do Steam aberto)" || quem="ligado na mão"
    printf '{"text":"󰊗","class":"ligado","tooltip":"Modo jogo %s\\nFoco preso · não perturbe · replay (Super+Shift+g salva)\\nClique: desligar"}\n' "$quem"
else
    echo '{"text":"󰊗","class":"desligado","tooltip":"Modo jogo desligado (liga sozinho com jogo do Steam)\nClique: ligar"}'
fi
