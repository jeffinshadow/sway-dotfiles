#!/usr/bin/env bash
# Estado do "não perturbe" do mako pro waybar (atualizado pelo sinal 8,
# que o sway/scripts/dnd.sh manda ao alternar).
if makoctl mode 2>/dev/null | grep -qx do-not-disturb; then
    echo '{"text":"󰂛","class":"dnd","tooltip":"Não perturbe LIGADO\nClique: desligar"}'
else
    echo '{"text":"󰂚","class":"normal","tooltip":"Notificações ativas\nClique: não perturbe · Direito: reabrir a última"}'
fi
