#!/usr/bin/env bash
# painel.sh <item> [estado|valor] — ponte entre o painel rápido do SwayNC e os scripts do desktop.
#   painel.sh <toggle> estado   imprime true/false (update-command: roda a cada abertura do painel)
#   painel.sh <toggle>          aplica o novo estado que o SwayNC passa em $SWAYNC_TOGGLE_STATE
#   painel.sh <botão>           ação simples (agente, salvar-replay, captura)
#   painel.sh mic|brilho [N]    slider: sem N imprime o valor 0-100; com N define
# Tudo num script só porque o SwayNC monta "/bin/sh -c \"<cmd>\"": aspas no config.json quebram.
set -uo pipefail
s="$HOME/.config/sway/scripts"
llm="$HOME/.dotfiles/apps/llm/llm.sh"
run="${XDG_RUNTIME_DIR:-/tmp}"
JBL="90:F2:60:29:60:66"
liga() { [[ "${SWAYNC_TOGGLE_STATE:-}" == true ]]; }
tf() { if "$@" >/dev/null 2>&1; then echo true; else echo false; fi; }
fecha() { swaync-client -cp >/dev/null 2>&1; }

item="${1:-}"; arg="${2:-}"
if [[ "$arg" == estado ]]; then
    case "$item" in
        jogo)     tf test -e "$run/modo-jogo" ;;
        tv)       tf test -e "$run/modo-tv" ;;
        dnd)      swaync-client -D ;;
        cafeina)  tf test -e "$run/cafeina" ;;
        luz)      tf pgrep -x gammastep ;;
        freesync) "$s/freesync.sh" DP-1 estado ;;
        replay)   tf pgrep -f "gpu-screen-recorder .*-r 60" ;;
        jbl)      tf sh -c "bluetoothctl info $JBL | grep -q 'Connected: yes'" ;;
        chat)     tf sh -c "curl -sf -m 0.3 http://127.0.0.1:8080/health" ;;
    esac
    exit 0
fi

case "$item" in
    jogo)     liga && a=ligar || a=desligar; setsid -f "$s/modo-jogo.sh" "$a" ;;
    tv)       fecha; liga && a=ligar || a=desligar; setsid -f "$s/modo-tv.sh" "$a" ;;
    dnd)      liga && swaync-client -dn || swaync-client -df ;;
    cafeina)  liga && "$s/idle.sh" pausar cafeina || "$s/idle.sh" retomar cafeina ;;
    luz)      if liga; then setsid -f gammastep >/dev/null 2>&1; else pkill -x gammastep; fi ;;
    freesync) liga && a=on || a=off; "$s/freesync.sh" DP-1 "$a" ;;
    replay)   liga && a=iniciar || a=parar; "$s/replay.sh" "$a" ;;
    jbl)      if liga; then bluetoothctl connect "$JBL"; else bluetoothctl disconnect "$JBL"; fi >/dev/null ;;
    chat)     if liga; then fecha; setsid -f "$llm" abrir; else "$llm" parar; fi ;;
    agente)   fecha; cd "$HOME/Claudio" && setsid -f "$HOME/.dotfiles/apps/llm/ia.sh" >/dev/null 2>&1 ;;
    salvar-replay) fecha; "$s/replay.sh" salvar ;;
    captura)  fecha; sleep 0.3; "$s/screenshot.sh" area ;;
    mic)
        if [[ -z "$arg" ]]; then
            wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{printf "%d", $2*100}'
        else
            wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${arg%.*}%"
        fi ;;
    brilho)
        if [[ -z "$arg" ]]; then cat "$run/brilho" 2>/dev/null || echo 50
        else "$s/brilho.sh" definir "${arg%.*}" --quieto; fi ;;
    *) echo "uso: $0 <item> [estado|valor]" >&2; exit 2 ;;
esac
