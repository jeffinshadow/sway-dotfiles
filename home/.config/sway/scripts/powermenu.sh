#!/usr/bin/env bash
# Menu de energia no rofi
# Liga/desliga: rofi aberto (ou travado) → fecha e sai
pkill -x rofi && exit 0

opts=$'󰌾  Bloquear\n󰤄  Suspender\n󰍃  Sair do Sway\n󰜉  Reiniciar\n󰐥  Desligar'
# Máquina com suspensão mascarada (servidor): some com a opção
if [[ "$(systemctl is-enabled suspend.target 2>/dev/null)" == masked ]]; then
    opts=$(grep -v Suspender <<<"$opts")
fi
choice=$(printf '%s' "$opts" | rofi -dmenu -i -p "Energia" -theme-str "window {width: 320px;} listview {lines: $(grep -c "" <<<"$opts");}")

# Sair/Reiniciar/Desligar pedem confirmação (um Enter errado derrubava a
# giratina, que é servidor). "Não" vem primeiro: Enter direto = cancela.
confirma() {
    local msg="$1" n
    # Reiniciar/desligar avisam dos containers (sair do sway não para eles)
    if [[ "${4:-}" == docker ]]; then
        n=$(docker ps -q 2>/dev/null | grep -c . || true)
        (( n > 0 )) && msg+=$'\n'"$n container(s) rodando vão parar."
    fi
    local r
    r=$(printf '%s\n' "󰜺  Não" "$2  Sim, $3" | rofi -dmenu -i -p "Confirmar" -mesg "$msg" \
        -theme-str 'window {width: 380px;} listview {lines: 2;}')
    [[ "$r" == *Sim* ]]
}

host=$(cut -d- -f2- /etc/hostname)
case "$choice" in
    *Bloquear)  swaylock -f ;;
    *Suspender) systemctl suspend ;;
    *Sair*)     confirma "Sair do Sway? Os apps abertos serão fechados." "󰍃" "sair" && swaymsg exit ;;
    *Reiniciar) confirma "Reiniciar a $host?" "󰜉" "reiniciar" docker && systemctl reboot ;;
    *Desligar)  confirma "Desligar a $host?" "󰐥" "desligar" docker && systemctl poweroff ;;
esac
