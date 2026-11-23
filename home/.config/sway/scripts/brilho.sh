#!/usr/bin/env bash
# brilho.sh mais|menos [passo] | definir N [--quieto] — brilho dos monitores externos pelo DDC/CI
# (ddcutil), os dois juntos (cada um mantém a diferença do outro). Aviso com barra na notificação.
# definir: leva o 32" a N% (o outro anda o mesmo tanto); usado pelo controle deslizante do painel.
# O nível fica em $XDG_RUNTIME_DIR/brilho (o painel lê daqui: ddcutil é lento).
# Super+F12 / Super+F11 (e as teclas de brilho, se o teclado tiver) na giratina.
set -uo pipefail
passo="${2:-10}"; quieto=false; [[ "${3:-}" == --quieto || "${2:-}" == --quieto ]] && quieto=true
nivel_cache="${XDG_RUNTIME_DIR:-/tmp}/brilho"
case "${1:-}" in
    mais) sinal="+" ;; menos) sinal="-" ;;
    definir)
        alvo="${2:?nível 0-100}"; atual=$(cat "$nivel_cache" 2>/dev/null || echo "")
        if [[ -z "$atual" ]]; then        # sem cache: lê o 32" uma vez
            c="${XDG_RUNTIME_DIR:-/tmp}/ddc-buses"
            [[ -s "$c" ]] && atual=$(ddcutil --bus "$(tail -1 "$c")" --brief getvcp 10 2>/dev/null | awk '{print $4}')
        fi
        d=$(( alvo - ${atual:-$alvo} )); (( d == 0 )) && exit 0
        (( d > 0 )) && sinal="+" || { sinal="-"; d=$(( -d )); }
        passo=$d ;;
    *) echo "uso: $0 mais|menos [passo] | definir N [--quieto]" >&2; exit 2 ;;
esac
command -v ddcutil >/dev/null || { notify-send -a brilho -u critical "Brilho" "ddcutil não está instalado."; exit 1; }

cache="${XDG_RUNTIME_DIR:-/tmp}/ddc-buses"         # detectar é lento: guarda os barramentos
[[ -s "$cache" ]] || ddcutil detect --brief 2>/dev/null | awk '/I2C bus/ {sub("/dev/i2c-","",$3); print $3}' > "$cache"

for b in $(cat "$cache"); do
    ddcutil --bus "$b" --noverify --sleep-multiplier 0.3 setvcp 10 "$sinal" "$passo" >/dev/null 2>&1 &
done
wait
# nível do primeiro monitor (o UltraGear) pro aviso
b=$(tail -1 "$cache")
nivel=$(ddcutil --bus "$b" --brief getvcp 10 2>/dev/null | awk '{print $4}')
[[ -n "$nivel" ]] && echo "$nivel" > "$nivel_cache"
$quieto && exit 0
notify-send -a brilho -t 1500 -i display-brightness -h "int:value:${nivel:-0}" \
    -h string:x-canonical-private-synchronous:brilho "Brilho" "${nivel:-?}%"
