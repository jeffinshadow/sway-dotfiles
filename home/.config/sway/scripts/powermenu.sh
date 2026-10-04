#!/usr/bin/env bash
# Menu de energia no rofi
# Liga/desliga: rofi aberto (ou travado) → fecha e sai
pkill -x rofi && exit 0

opts=$'󰌾  Bloquear\n󰤄  Suspender\n󰍃  Sair do Sway\n󰜉  Reiniciar\n󰐥  Desligar'
# Máquina com suspensão mascarada (servidor): some com a opção
if [[ "$(systemctl is-enabled suspend.target 2>/dev/null)" == masked ]]; then
    opts=$(grep -v Suspender <<<"$opts")
fi
choice=$(printf '%s' "$opts" | rofi -dmenu -i -p "Energia" -theme-str "window {width: 320px;} listview {lines: $(grep -c "" <<<"$opts");}")
case "$choice" in
    *Bloquear)  swaylock -f ;;
    *Suspender) systemctl suspend ;;
    *Sair*)     swaymsg exit ;;
    *Reiniciar) systemctl reboot ;;
    *Desligar)  systemctl poweroff ;;
esac
