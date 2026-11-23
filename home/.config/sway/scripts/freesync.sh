#!/usr/bin/env bash
# freesync.sh [saída] [toggle|on|off|estado] — adaptive sync (FreeSync). Sem argumentos: alterna a saída
# em foco e avisa (atalho). "estado" imprime true/false (painel rápido).
saida="${1:-}"; acao="${2:-toggle}"
[[ "$saida" == toggle || "$saida" == on || "$saida" == off || "$saida" == estado ]] && { acao=$saida; saida=""; }
[[ -n "$saida" ]] || saida=$(swaymsg -t get_outputs | python3 -c '
import json, sys
print(next(o["name"] for o in json.load(sys.stdin) if o.get("focused")))')
status() { swaymsg -t get_outputs | python3 -c '
import json, sys
print(next(o.get("adaptive_sync_status", "?") for o in json.load(sys.stdin) if o["name"] == sys.argv[1]))' "$saida"; }
if [[ "$acao" == estado ]]; then [[ "$(status)" == enabled ]] && echo true || echo false; exit 0; fi
case "$acao" in on) v=enable ;; off) v=disable ;; *) v=toggle ;; esac
swaymsg -q output "$saida" adaptive_sync "$v"
case $(status) in enabled) texto="ligado" ;; disabled) texto="desligado" ;; *) texto=$(status) ;; esac
notify-send -a freesync -t 2500 "FreeSync" "$texto em $saida"
