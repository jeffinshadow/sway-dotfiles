#!/usr/bin/env bash
# Liga/desliga a escuta do "ei giratina" (Super+Shift+z / clique na waybar). Saída JSON pra waybar com "estado".
u=giratina-voz.service
case "${1:-alternar}" in
  alternar) if systemctl --user is-active -q $u; then systemctl --user stop $u; notify-send -a giratina -t 2500 "Giratina" "🎙 parei de ouvir"
            else systemctl --user start $u; notify-send -a giratina -t 2500 "Giratina" "🎙 ouvindo \"ei giratina\""; fi
            pkill -RTMIN+11 waybar ;;
  estado)   systemctl --user cat $u >/dev/null 2>&1 || { echo '{"text":""}'; exit; }
            if [[ -e "${XDG_RUNTIME_DIR}/giratina-voz" ]]; then echo '{"text":"󰍬","tooltip":"Giratina ouvindo (clique: desligar)","class":"on"}'
            elif systemctl --user is-active -q $u; then echo '{"text":"󰍭","tooltip":"Giratina pausado (modo jogo)","class":"pausa"}'
            else echo '{"text":"󰍭","tooltip":"Giratina desligado (clique: ouvir)","class":"off"}'; fi ;;
esac
