#!/usr/bin/env bash
# floating.sh — alterna flutuante/lado a lado na janela focada e avisa.
# O aviso ajuda quando a janela sai do tiling no mesmo tamanho que tinha
# (navegador etc.): parece que nada mudou, mas ela já está flutuando.
set -euo pipefail

swaymsg -q floating toggle

# Janela focada depois da troca: floating_con = flutuante
info=$(swaymsg -t get_tree -r | jq -r '
    [recurse(.nodes[]?, .floating_nodes[]?) | select(.focused)][0] // empty
    | [ (if .type == "floating_con" then "ativado" else "desativado" end),
        (.app_id // .window_properties.class // ""),
        (.name // "") ] | @tsv')
[[ -n "$info" ]] || exit 0
IFS=$'\t' read -r estado app titulo <<<"$info"

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
