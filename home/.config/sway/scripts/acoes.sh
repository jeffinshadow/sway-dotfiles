#!/usr/bin/env bash
# acoes.sh — menu (rofi) de ações do sistema (Super+m): o que antes se resolvia no terminal.
pkill -x rofi && exit 0
s="$HOME/.config/sway/scripts"; llm="$HOME/.dotfiles/apps/llm/llm.sh"
JBL="90:F2:60:29:60:66"
aviso() { notify-send -a acoes -t "${3:-3000}" "$1" "$2"; }
term() { ghostty --title="$1" -e bash -c "$2"'; echo; read -rsn1 -p "[tecla pra fechar]"' & }
menu() { rofi -dmenu -i -p "$1" ${2:+-mesg "$2"} -theme-str "window {width: ${4:-440px};} listview {lines: $3;}"; }

# estado resumido no topo do menu
llm_est=$("$llm" estado 2>/dev/null)
bkp=$(tail -1 "$HOME/backups/backup-drive.log" 2>/dev/null | cut -c1-60)
falhas=$( (systemctl --failed --no-legend --plain; systemctl --user --failed --no-legend --plain) 2>/dev/null | grep -c .)
mesg="LLM: ${llm_est:-?} · serviços com falha: $falhas"$'\n'"último backup: ${bkp:-?}"

ops="󰂰  Reconectar a JBL
󰓃  Saída de áudio…
󰍬  Microfone…
󰆼  Backup no Drive agora
󰒓  Serviços com falha / logs
󰚰  Atualizações disponíveis
󰋊  Discos e memória
󰭹  LLM: abrir o Chat local
󰚌  LLM: parar (libera a VRAM)
󰑓  Recarregar o Sway (e a waybar)"
op=$(printf '%s' "$ops" | menu "Ações" "$mesg" "$(grep -c "" <<<"$ops")") || exit 0

escolher_dispositivo() {   # $1 = sinks|sources
    local tipo=$1 padrao lista nome
    padrao=$(pactl "get-default-${tipo%s}")
    lista=$(pactl -f json list "$tipo" | python3 -c '
import json, sys
for d in json.load(sys.stdin):
    if d["name"].endswith(".monitor") or "easyeffects" in d["name"]: continue
    print(d["name"] + "\t" + d.get("description", d["name"]))')
    [[ -n "$lista" ]] || { aviso "Áudio" "Nenhum dispositivo encontrado."; return; }
    nome=$(awk -F'\t' -v p="$padrao" '{printf "%s%s\t%s\n", ($1==p ? "󰄬  " : "    "), $2, $1}' <<<"$lista" \
        | menu "${tipo/sinks/Saída}" "" "$(grep -c "" <<<"$lista")" 560px | awk -F'\t' '{print $2}') || return
    [[ -n "$nome" ]] || return
    pactl "set-default-${tipo%s}" "$nome"
    # move o que já está tocando/gravando pro novo padrão
    if [[ $tipo == sinks ]]; then for i in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input "$i" "$nome"; done
    else for i in $(pactl list short source-outputs | cut -f1); do pactl move-source-output "$i" "$nome" 2>/dev/null; done; fi
    aviso "Áudio" "Padrão agora: $(awk -F'\t' -v n="$nome" '$1==n{print $2}' <<<"$lista")"
}

case "$op" in
    *JBL*)
        aviso "JBL" "Conectando…" 2000
        if bluetoothctl connect "$JBL" | grep -q "successful"; then
            sleep 2; sink=$(pactl list short sinks | awk -v m="${JBL//:/_}" '$2 ~ m {print $2; exit}')
            [[ -n "$sink" ]] && pactl set-default-sink "$sink"
            aviso "JBL" "Conectada e como saída padrão."
        else aviso "JBL" "Não conectou (está ligada e por perto?)."; fi ;;
    *Saída*)      escolher_dispositivo sinks ;;
    *Microfone*)  escolher_dispositivo sources ;;
    *Backup*)     systemctl --user start --no-block backup-drive.service && aviso "Backup" "Rodando em segundo plano (log: ~/backups/backup-drive.log)." 5000 ;;
    *Serviços*)   term "serviços" 'echo "== sistema"; systemctl --failed; echo; echo "== usuário"; systemctl --user --failed; echo; echo "== erros recentes (1 h)"; journalctl -p err --since -1h --no-pager | tail -30' ;;
    *Atualizações*) term "atualizações" 'echo "== repositórios"; checkupdates; echo; echo "== AUR"; paru -Qua; echo; echo "Pra atualizar: paru -Syu"' ;;
    *Discos*)     term "discos" 'df -h -x tmpfs -x devtmpfs -x efivarfs; echo; free -h' ;;
    *Chat*)       setsid -f "$llm" abrir >/dev/null 2>&1 ;;
    *parar*)      "$llm" parar ;;
    *Recarregar*) swaymsg reload >/dev/null && aviso "Sway" "Configuração recarregada." ;;
esac
