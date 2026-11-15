#!/usr/bin/env bash
# Liga/desliga o adaptive sync (FreeSync) da saída em foco e avisa o estado.
saida=$(swaymsg -t get_outputs | python3 -c '
import json, sys
print(next(o["name"] for o in json.load(sys.stdin) if o.get("focused")))')
swaymsg -q output "$saida" adaptive_sync toggle
estado=$(swaymsg -t get_outputs | python3 -c '
import json, sys
print(next(o.get("adaptive_sync_status", "?") for o in json.load(sys.stdin) if o["name"] == sys.argv[1]))' "$saida")
case $estado in
    enabled)  texto="ligado" ;;
    disabled) texto="desligado" ;;
    *)        texto=$estado ;;
esac
notify-send -t 2500 "FreeSync" "$texto em $saida"
