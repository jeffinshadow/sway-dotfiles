#!/usr/bin/env bash
# homolog.sh — menu (rofi) dos projetos de homologação em /srv/docker (Super+o; clique direito no
# módulo do Docker na waybar). 1º nível: projetos com o estado; 2º: ações. O que tem saída longa
# (atualizar, logs, status, shell) abre num terminal; parar/atualizar pedem confirmação.
# Atualizar usa o deploy.sh do projeto quando existe (backup + migrations + rollback); senão
# git pull --ff-only + docker compose up -d --build.
pkill -x rofi && exit 0
raiz=/srv/docker
term() { ghostty --title="$1" -e bash -c "$2"'; echo; read -rsn1 -p "[tecla pra fechar]"' & }
rofi_menu() { rofi -dmenu -i -p "$1" ${2:+-mesg "$2"} -theme-str "window {width: 460px;} listview {lines: $3;}"; }
confirma() {
    local r; r=$(printf '%s\n' "󰜺  Não" "$2  Sim, $3" | rofi -dmenu -i -p "Confirmar" -mesg "$1" \
        -theme-str 'window {width: 400px;} listview {lines: 2;}')
    [[ "$r" == *Sim* ]]
}
estado() {   # "rodando 4/4" | "parado (4)" | "sem containers"
    local d="$1" total rod
    total=$(docker compose --project-directory "$d" ps -a -q 2>/dev/null | grep -c .)
    rod=$(docker compose --project-directory "$d" ps -q --status running 2>/dev/null | grep -c .)
    if (( total == 0 )); then echo "sem containers"
    elif (( rod == total )); then echo "rodando $rod/$total"
    elif (( rod == 0 )); then echo "parado ($total)"
    else echo "parcial $rod/$total"; fi
}

# 1º nível: projetos
mapfile -t projs < <(find "$raiz" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
(( ${#projs[@]} )) || { notify-send -a homolog "Homologação" "Nenhum projeto em $raiz"; exit 0; }
linhas=""
for p in "${projs[@]}"; do
    e=$(estado "$raiz/$p"); case "$e" in rodando*) i="󰐊" ;; parcial*) i="󰏤" ;; *) i="󰓛" ;; esac
    linhas+="$i  $p  —  $e"$'\n'
done
esc=$(printf '%s' "$linhas" | rofi_menu "Homologação" "" "${#projs[@]}") || exit 0
proj=$(awk '{print $2}' <<<"$esc"); d="$raiz/$proj"; [[ -d "$d" ]] || exit 0
dc="docker compose --project-directory '$d'"

# 2º nível: ações
commit=$(git -C "$d" log -1 --format='%h · %cr · %s' 2>/dev/null | cut -c1-70)
portas=$(docker compose --project-directory "$d" ps --format '{{.Publishers}}' 2>/dev/null \
    | grep -oE '"PublishedPort":[0-9]+|[0-9.]*:([0-9]+)->' | grep -oE '[0-9]+' | sort -un | grep -v '^0$')
ops="󰚰  Atualizar (pull + deploy)
󰐊  Subir
󰜉  Reiniciar
󰓛  Parar
󰈸  Logs (ao vivo)
󰋽  Status
󰆍  Shell num serviço
󰉋  Terminal na pasta"
for pt in $portas; do ops+=$'\n'"󰖟  Abrir http://localhost:$pt"; done
op=$(printf '%s' "$ops" | rofi_menu "$proj" "$(estado "$d") · $commit" "$(grep -c "" <<<"$ops")") || exit 0

case "$op" in
    *Atualizar*)
        sujo=$(git -C "$d" status --short 2>/dev/null | head -5)
        [[ -n "$sujo" ]] && { notify-send -a homolog -u critical "Homologação: $proj" "Árvore do git suja; não atualizei:"$'\n'"$sujo"; exit 1; }
        confirma "Atualizar $proj? (git pull + build + subir)" "󰚰" "atualizar" || exit 0
        if [[ -x "$d/deploy.sh" ]]; then term "deploy $proj" "cd '$d' && ./deploy.sh"
        else term "atualizar $proj" "cd '$d' && git pull --ff-only && $dc up -d --build && $dc ps"; fi ;;
    *Subir*)     term "subir $proj" "$dc up -d && $dc ps" ;;
    *Reiniciar*) term "reiniciar $proj" "$dc restart && $dc ps" ;;
    *Parar*)     confirma "Parar os containers de $proj? (os dados ficam)" "󰓛" "parar" && term "parar $proj" "$dc stop && $dc ps -a" ;;
    *Logs*)      ghostty --title="logs $proj" -e bash -c "$dc logs -f --tail 200" & ;;
    *Status*)    term "status $proj" "$dc ps -a; echo; git -C '$d' log -3 --format='%h %cr %s'" ;;
    *Shell*)
        mapfile -t svcs < <(docker compose --project-directory "$d" ps --services --status running 2>/dev/null)
        (( ${#svcs[@]} )) || { notify-send -a homolog "Homologação: $proj" "Nenhum serviço rodando."; exit 0; }
        s=$(printf '%s\n' "${svcs[@]}" | rofi_menu "Shell em" "" "${#svcs[@]}") || exit 0
        ghostty --title="shell $proj/$s" -e bash -c "$dc exec '$s' sh -c 'command -v bash >/dev/null && exec bash || exec sh'" & ;;
    *Terminal*)  ghostty --working-directory="$d" & ;;
    *Abrir*)     xdg-open "${op##* }" >/dev/null 2>&1 & ;;
esac
