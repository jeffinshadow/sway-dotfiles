#!/usr/bin/env bash
# brilho.sh mais|menos [passo] — brilho dos monitores externos pelo DDC/CI (ddcutil),
# os dois juntos (cada um mantém a diferença do outro). Aviso com barra no mako.
# Super+F12 / Super+F11 (e as teclas de brilho, se o teclado tiver) na giratina.
set -uo pipefail
passo="${2:-10}"
case "${1:-}" in mais) sinal="+" ;; menos) sinal="-" ;; *) echo "uso: $0 mais|menos [passo]" >&2; exit 2 ;; esac
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
notify-send -a brilho -t 1500 -i display-brightness -h "int:value:${nivel:-0}" \
    -h string:x-canonical-private-synchronous:brilho "Brilho" "${nivel:-?}%"
