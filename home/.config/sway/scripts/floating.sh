#!/usr/bin/env bash
# floating.sh — alterna flutuante/lado a lado na janela focada e avisa.
# Ao flutuar, a janela encolhe pra 65% x 70% da área útil e vai pro centro:
# sem isso ela sai do tiling no mesmo tamanho (navegador etc.) e parece
# que nada mudou. O aviso confirma a troca.
set -euo pipefail

LARGURA=65   # % da área do workspace (sem a barra)
ALTURA=70

# Janela focada antes da troca: floating_con = já está flutuando
info=$(swaymsg -t get_tree -r | jq -r '
    [recurse(.nodes[]?, .floating_nodes[]?) | select(.focused)][0] // empty
    | [ .type, .id, (.app_id // .window_properties.class // ""), (.name // "") ]
    | @tsv')
[[ -n "$info" ]] || exit 0
IFS=$'\t' read -r tipo id app titulo <<<"$info"

if [[ "$tipo" == "floating_con" ]]; then
    swaymsg -q "[con_id=$id] floating disable"
    estado="desativado"
else
    # Tudo num comando só: separado, o tamanho que o sway dá ao flutuar
    # atropela o resize. Em px porque o 'ppt' não vale pra flutuante.
    read -r ws_l ws_a < <(swaymsg -t get_workspaces -r \
        | jq -r '.[] | select(.focused) | "\(.rect.width) \(.rect.height)"')
    swaymsg -q "[con_id=$id] floating enable, resize set width $(( ws_l * LARGURA / 100 )) px height $(( ws_a * ALTURA / 100 )) px, move position center"
    estado="ativado"
fi

# Nome amigável pelo .desktop (com.mitchellh.ghostty → Ghostty)
nome=""
for d in ~/.local/share/applications /usr/share/applications; do
    for f in "$d/$app.desktop" "$d/${app,,}.desktop"; do
        [[ -n "$app" && -f "$f" ]] || continue
        nome=$(sed -n 's/^Name=//p' "$f" | head -1)
        break 2
    done
done
[[ -z "$nome" && -n "$app" ]] && nome="${app##*.}"

janela="${nome:-janela}"
[[ -n "$titulo" ]] && janela="$janela — $titulo"
(( ${#janela} > 80 )) && janela="${janela:0:79}…"

notify-send -a floating -t 2500 -i "${app,,}" "Floating $estado" "$janela"
