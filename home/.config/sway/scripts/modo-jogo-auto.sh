#!/usr/bin/env bash
# modo-jogo-auto.sh — vigia as janelas do Sway: abriu jogo do Steam (class steam_app_<id>,
# Proton/XWayland; inclui o Content Manager do AC) → liga o modo jogo; fechou o último →
# desliga, mas só se foi este vigia que ligou (modo ligado na mão com Super+g fica).
# Sobe pelo 50-autostart; reinicia sozinho se o sway reconectar.
set -uo pipefail
estado="${XDG_RUNTIME_DIR:-/tmp}/modo-jogo"
jogo='^steam_app_[0-9]+$'
scripts="$HOME/.config/sway/scripts"

ha_jogo() {
    swaymsg -t get_tree -r | jq -e --arg re "$jogo" \
        '[recurse(.nodes[]?, .floating_nodes[]?) | select(.window_properties.class? // "" | test($re))] | length > 0' >/dev/null
}

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/modo-jogo-auto.lock"
flock -n 9 || exit 0                               # já tem um rodando

while true; do
    swaymsg -t subscribe -m '["window"]' 2>/dev/null | while read -r ev; do
        tipo=$(jq -r '.change' <<<"$ev")
        classe=$(jq -r '.container.window_properties.class // ""' <<<"$ev")
        [[ "$classe" =~ $jogo ]] || continue
        case "$tipo" in
            new) [[ -e "$estado" ]] || MODO_JOGO_ORIGEM=auto "$scripts/modo-jogo.sh" ligar ;;
            close)
                sleep 1
                if ! ha_jogo && [[ "$(cat "$estado" 2>/dev/null)" == auto ]]; then
                    "$scripts/modo-jogo.sh" desligar
                fi ;;
        esac
    done
    sleep 2                                        # sway reiniciou/recarregou o IPC: tenta de novo
done
