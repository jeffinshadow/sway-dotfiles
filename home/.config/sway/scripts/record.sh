#!/usr/bin/env bash
# record.sh area|tela — grava a tela com wf-recorder (sem áudio).
#   area → seleciona com o slurp (Esc cancela)
#   tela → a tela focada inteira
# Chamar de novo (qualquer um dos dois) para a gravação. Enquanto grava,
# a waybar mostra o REC (custom/rec, sinal 9); clicar nele também para.
set -euo pipefail

estado="${XDG_RUNTIME_DIR:-/tmp}/gravacao"   # caminho do arquivo + início
waybar() { pkill -RTMIN+9 waybar || true; }

if pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder   # o processo que gravou avisa quando fechar o arquivo
    exit 0
fi

if ! command -v wf-recorder >/dev/null; then
    notify-send -a gravacao -u critical "Gravação" "wf-recorder não está instalado (pacman -S wf-recorder)."
    exit 1
fi

case "${1:-area}" in
    area) geom=$(slurp -d) || exit 0 ;;   # Esc no slurp: sai quieto
    tela) out=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name') ;;
    *)    echo "uso: $0 area|tela" >&2; exit 2 ;;
esac

dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Gravações"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"

if [[ -n "${geom:-}" ]]; then
    wf-recorder -g "$geom" -f "$file" &>/dev/null &
else
    wf-recorder -o "$out" -f "$file" &>/dev/null &
fi
printf '%s\n%s\n' "$file" "$(date +%s)" > "$estado"
sleep 0.3; waybar
wait || true

rm -f "$estado"; waybar
if [[ -s "$file" ]]; then
    notify-send -a gravacao -i video-x-generic "Gravação salva" "$file"
else
    rm -f "$file"
    notify-send -a gravacao -u critical "Gravação" "Falhou: nada foi gravado."
fi
