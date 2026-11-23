#!/usr/bin/env bash
# idle.sh iniciar | pausar <motivo> | retomar <motivo> | estado — dono único do swayidle principal
# (bloqueio aos 5 min, tela apagada aos 5,5). Vários motivos podem pausar ao mesmo tempo (cafeina do
# painel, tv do modo TV): só volta quando nenhum sobra. Antes, sair do modo TV religava o swayidle
# mesmo com a cafeína ligada. A suspensão automática (latios) fica no arquivo do host, à parte.
set -uo pipefail
run="${XDG_RUNTIME_DIR:-/tmp}"; dir="$run/idle-pausa"; pid="$run/swayidle.pid"
mkdir -p "$dir"
rodando() { [[ -s "$pid" ]] && kill -0 "$(cat "$pid")" 2>/dev/null; }
iniciar() {
    [[ -n "$(ls -A "$dir")" ]] && return 0          # algum motivo ainda pausa
    rodando && return 0
    pgrep -f "^swayidle -w timeout 300 swaylock -f" >/dev/null && return 0
    setsid swayidle -w \
        timeout 300 'swaylock -f' \
        timeout 330 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
        before-sleep 'swaylock -f' >/dev/null 2>&1 &
    echo $! > "$pid"
}
parar() {
    if rodando; then kill "$(cat "$pid")"
    else pkill -f "^swayidle -w timeout 300 swaylock -f" ; fi   # um iniciado sem pidfile (sessão antiga)
    rm -f "$pid"
}
case "${1:-}" in
    iniciar) iniciar ;;
    pausar)  touch "$dir/${2:?motivo}"; parar ;;
    retomar) rm -f "$dir/${2:?motivo}"; iniciar ;;
    estado)  if rodando; then echo ativo; else echo "pausado: $(ls "$dir" | tr '\n' ' ')"; fi ;;
    *) echo "uso: $0 iniciar | pausar <motivo> | retomar <motivo> | estado" >&2; exit 2 ;;
esac
