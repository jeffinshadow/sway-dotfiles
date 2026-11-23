#!/usr/bin/env bash
# modo-jogo.sh [alternar|ligar|desligar] — modo jogo:
#  - foco NÃO segue o mouse (o cursor que escorrega pro monitor vertical não rouba o jogo);
#  - não perturbe (alertas críticos continuam aparecendo);
#  - replay buffer dos últimos 60 s (replay.sh; Super+Shift+g salva);
#  - escalonador sched_ext LAVD (modo Gaming) no lugar do EEVDF do kernel: no teste de 22/11/2026
#    (apps/bench-sched, Cyberpunk) deu 0,1% low +27% e 20x menos travadas sem carga, e +32% de
#    FPS com build pesado rodando junto; fora do jogo o EEVDF tem latência melhor, então volta.
# Super+g alterna na mão. O modo-jogo-auto.sh liga sozinho quando abre um jogo do
# Steam e desliga quando o último fecha (só se foi ele quem ligou).
set -euo pipefail
estado="${XDG_RUNTIME_DIR:-/tmp}/modo-jogo"        # existe = ligado; conteúdo: manual|auto
scripts="$HOME/.config/sway/scripts"
trava_scx="${XDG_RUNTIME_DIR:-/tmp}/modo-jogo-scx.lock"
# Comandos do escalonador em fila (flock): o "parar" espera o "iniciar" terminar, mesmo se o
# modo jogo for ligado e desligado em seguida. Em segundo plano: o scx_loader leva uns segundos.
scx() { command -v scxctl >/dev/null && setsid -f flock "$trava_scx" timeout 30 scxctl "$@" >/dev/null 2>&1; }
origem="${MODO_JOGO_ORIGEM:-manual}"

ligar() {
    [[ -e "$estado" ]] && return 0
    notify-send -a jogo -t 2000 -i input-gaming "Modo jogo ligado" \
        "Foco preso, não perturbe, escalonador LAVD e replay (Super+Shift+g salva 60 s)."
    sleep 2                                        # o aviso aparece antes do não perturbe
    echo "$origem" > "$estado"
    swaymsg -q focus_follows_mouse no
    makoctl mode -a do-not-disturb >/dev/null || true
    pkill -RTMIN+8 waybar || true; pkill -RTMIN+10 waybar || true
    "$scripts/replay.sh" iniciar
    scx start --sched lavd --mode gaming
}

desligar() {
    [[ -e "$estado" ]] || return 0
    rm -f "$estado"
    swaymsg -q focus_follows_mouse yes
    "$scripts/replay.sh" parar
    scx stop                                       # volta pro EEVDF
    makoctl mode -r do-not-disturb >/dev/null || true
    pkill -RTMIN+8 waybar || true; pkill -RTMIN+10 waybar || true
    notify-send -a jogo -t 2500 -i input-gaming "Modo jogo desligado" "Foco segue o mouse e notificações de volta."
}

case "${1:-alternar}" in
    ligar) ligar ;;
    desligar) desligar ;;
    alternar) if [[ -e "$estado" ]]; then desligar; else ligar; fi ;;
    *) echo "uso: $0 [alternar|ligar|desligar]" >&2; exit 2 ;;
esac
