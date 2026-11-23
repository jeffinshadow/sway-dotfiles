#!/usr/bin/env bash
# replay.sh iniciar|parar|salvar — replay buffer com o gpu-screen-recorder (AUR):
# grava sem parar na memória os últimos 60 s do monitor principal (HEVC pela GPU,
# com o áudio do sistema) e só grava em disco quando você pede (salvar).
# Quem liga/desliga é o modo-jogo.sh; o atalho Super+Ctrl+Print salva.
set -euo pipefail
OUT="DP-1"                                     # monitor de jogo
dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Replays"

if ! command -v gpu-screen-recorder >/dev/null; then
    [[ "${1:-}" == salvar ]] && notify-send -a gravacao -u critical "Replay" \
        "gpu-screen-recorder não está instalado (paru -S gpu-screen-recorder)."
    exit 0
fi

case "${1:-}" in
    iniciar)
        pgrep -f "gpu-screen-recorder .*-r 60" >/dev/null && exit 0
        mkdir -p "$dir"
        setsid -f gpu-screen-recorder -w "$OUT" -f 60 -k hevc -a default_output \
            -c mp4 -r 60 -o "$dir" &>/dev/null ;;
    parar)
        pkill -INT -f "gpu-screen-recorder .*-r 60" || true ;;
    salvar)
        if pkill -USR1 -f "gpu-screen-recorder .*-r 60"; then
            notify-send -a gravacao -t 2500 -i video-x-generic "Replay salvo" "Últimos 60 s em $dir"
        else
            notify-send -a gravacao -u critical "Replay" "O replay não está rodando (liga com o modo jogo, Super+g)."
        fi ;;
    *) echo "uso: $0 iniciar|parar|salvar" >&2; exit 2 ;;
esac
