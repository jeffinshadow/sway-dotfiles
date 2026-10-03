#!/usr/bin/env bash
# Menu de energia no rofi
opts=$'󰌾  Bloquear\n󰤄  Suspender\n󰍃  Sair do Sway\n󰜉  Reiniciar\n󰐥  Desligar'
choice=$(printf '%s' "$opts" | rofi -dmenu -i -p "Energia" -theme-str 'window {width: 320px;} listview {lines: 5;}')
case "$choice" in
    *Bloquear)  swaylock -f ;;
    *Suspender) systemctl suspend ;;
    *Sair*)     swaymsg exit ;;
    *Reiniciar) systemctl reboot ;;
    *Desligar)  systemctl poweroff ;;
esac
