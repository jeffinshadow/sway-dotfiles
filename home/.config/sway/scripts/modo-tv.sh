#!/usr/bin/env bash
# modo-tv.sh — "Smart TV" no 32" (DP-1), pra ver da cama com o celular de controle
# (controle remoto: apps/controle-tv, PWA em https://shadowtec-giratina.local:8443).
#   ligar | desligar | alternar          entra/sai do modo TV
#   ligar vertical                       idem, mas o monitor vertical continua aceso (usar o PC junto)
#   youtube | music | max                abre o app (fecha o que estiver aberto)
#   fechar                               fecha o app aberto (continua no modo TV)
#   zoom in|out|reset                    zoom do navegador (Ctrl + = / - / 0). No YouTube não faz nada:
#                                        a interface de TV trava o próprio tamanho (nem a escala do Sway muda)
#   app                                  imprime o app aberto: youtube, music, max ou nenhum
#   estado                               imprime "ligado" ou "desligado"
# Ligar: desliga o monitor vertical, áudio na JBL, não perturbe, tela não apaga,
# workspace "TV" no 32". Desligar: desfaz tudo.
set -uo pipefail
estado="${XDG_RUNTIME_DIR:-/tmp}/modo-tv"
TV="$HOME/.local/share/modo-tv"
JBL="90:F2:60:29:60:66"
# YouTube só entrega a interface de TV (youtube.com/tv) pra navegador de TV. A qualidade máxima
# depende do aparelho declarado (testado em 22/11/2026, vídeo 4K): Tizen 6/7, Cobalt, PS5 e Xbox
# One travam em 720p; PS4 libera até 1440p (limite da tela).
UA="Mozilla/5.0 (PS4; Leanback Shell) Gecko/20100101 Firefox/65.0 LeanbackShell/01.00.01.75 Sony PS4/ (PS4, , no, CH)"

fechar_apps() {
    pkill -f -- "--user-data-dir=$TV/chromium" 2>/dev/null
    pkill -f -- "--profile $TV/firefox" 2>/dev/null
    sleep 0.5
}

audio_jbl() {
    if ! bluetoothctl info "$JBL" 2>/dev/null | grep -q "Connected: yes"; then
        bluetoothctl connect "$JBL" >/dev/null 2>&1; sleep 3
    fi
    local sink; sink=$(pactl list short sinks | awk -v m="${JBL//:/_}" '$2 ~ m {print $2; exit}')
    [[ -n "$sink" ]] && pactl set-default-sink "$sink"
}

firefox_tv() {   # perfil próprio: DRM (Widevine) pro HBO Max, sem tela de boas-vindas
    mkdir -p "$TV/firefox"
    cp -f "$HOME/.config/sway/scripts/modo-tv-firefox.js" "$TV/firefox/user.js"
    setsid -f firefox --profile "$TV/firefox" --no-remote --kiosk "$1" >/dev/null 2>&1
}

case "${1:-alternar}" in
    estado) [[ -e "$estado" ]] && echo ligado || echo desligado ;;
    alternar) [[ -e "$estado" ]] && exec "$0" desligar || exec "$0" ligar ;;
    ligar)
        touch "$estado"
        makoctl mode -a do-not-disturb >/dev/null 2>&1; pkill -RTMIN+8 waybar
        pkill -x swayidle                                  # nada de bloquear/apagar no meio do filme
        [[ "${2:-}" == vertical ]] || swaymsg -q 'output HDMI-A-1 power off'
        swaymsg -q 'focus output DP-1; workspace TV'
        audio_jbl
        exec "$0" youtube ;;
    desligar)
        rm -f "$estado"
        fechar_apps
        swaymsg -q 'output HDMI-A-1 power on'
        swaymsg -q 'output DP-1 scale 1'                      # desfaz o zoom do YouTube
        swaymsg -q 'workspace 1'
        pgrep -x swayidle >/dev/null || setsid -f swayidle -w \
            timeout 300 'swaylock -f' \
            timeout 330 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
            before-sleep 'swaylock -f' >/dev/null 2>&1
        makoctl mode -r do-not-disturb >/dev/null 2>&1; pkill -RTMIN+8 waybar ;;
    youtube)
        [[ -e "$estado" ]] || exec "$0" ligar
        fechar_apps; swaymsg -q 'focus output DP-1; workspace TV'; swaymsg -q 'output DP-1 scale 1'
        mkdir -p "$TV/chromium"
        setsid -f chromium --user-data-dir="$TV/chromium" --user-agent="$UA" --kiosk \
            --noerrdialogs --disable-session-crashed-bubble --no-first-run \
            --autoplay-policy=no-user-gesture-required --app=https://www.youtube.com/tv >/dev/null 2>&1 ;;
    music)
        [[ -e "$estado" ]] || "$0" ligar >/dev/null
        fechar_apps; swaymsg -q 'output DP-1 scale 1; focus output DP-1; workspace TV'
        firefox_tv https://music.youtube.com ;;
    max)
        [[ -e "$estado" ]] || "$0" ligar >/dev/null
        fechar_apps; swaymsg -q 'output DP-1 scale 1; focus output DP-1; workspace TV'
        firefox_tv https://play.hbomax.com ;;
    fechar) fechar_apps; swaymsg -q 'output DP-1 scale 1' ;;
    app)
        if pgrep -f -- "--user-data-dir=$TV/chromium" >/dev/null; then echo youtube
        elif pgrep -f -- "--profile $TV/firefox.*music.youtube" >/dev/null; then echo music
        elif pgrep -f -- "--profile $TV/firefox" >/dev/null; then echo max
        else echo nenhum; fi ;;
    zoom)
        if pgrep -f -- "--user-data-dir=$TV/chromium" >/dev/null; then
            :                                                  # YouTube na TV: sem zoom
        else
            case "${2:-reset}" in in) k=equal ;; out) k=minus ;; *) k=0 ;; esac
            wtype -M ctrl -k "$k" -m ctrl
        fi ;;
    *) echo "uso: $0 ligar|desligar|alternar|youtube|music|max|fechar|zoom in|out|reset|estado" >&2; exit 2 ;;
esac
