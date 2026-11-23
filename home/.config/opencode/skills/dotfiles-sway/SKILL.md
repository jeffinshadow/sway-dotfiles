---
name: dotfiles-sway
description: Editar config do Sway, waybar, rofi, swaync (painel e notificações, ~/.config/swaync + scripts/painel.sh), ghostty, foot, MangoHud ou scripts em ~/.config/sway/scripts; atalhos de teclado; regras de janela; recarregar o desktop.
---
# Dotfiles e Sway

Repositório: ~/.dotfiles (GitHub jeffinshadow/sway-dotfiles). ~/.config/* são symlinks pra ~/.dotfiles/home/.config/*.

## Mapa
- Sway: ~/.dotfiles/home/.config/sway/config.d/
  - 00-vars.conf (variáveis, $mod), 10-appearance.conf (cores, bar {} que sobe a waybar),
    20-input.conf, 30-binds.conf (atalhos), 40-rules.conf (regras de janela), 50-autostart.conf
  - Por máquina: ~/.dotfiles/hosts/shadowtec-giratina/sway.conf (ligado como config.d/90-host.conf)
- Scripts: ~/.dotfiles/home/.config/sway/scripts/ (modo-tv.sh, modo-jogo.sh, brilho.sh, replay.sh...)
- Waybar: ~/.dotfiles/home/.config/waybar/{config.jsonc,style.css}; cores do host em hosts/shadowtec-giratina/waybar.css
- Monitores: DP-1 (LG 32" 2560x1440 165 Hz, principal) e HDMI-A-1 (24" vertical).

## Passos
1. `readlink -f ~/.config/<arquivo>` pra achar o arquivo real.
2. Leia o arquivo e edite o alvo dentro de ~/.dotfiles (nunca `sed -i` em ~/.config).
3. Valide: `sway -C -c ~/.config/sway/config` (sem saída = ok).
4. Peça ao usuário pra recarregar (`swaymsg reload`, Super+Shift+c) — recarrega a waybar junto.
5. Script novo: `chmod +x`; arquivo novo em ~/.dotfiles/home precisa de `~/.dotfiles/install.sh` (usuário roda).

## Consultas úteis
- `swaymsg -t get_outputs`, `swaymsg -t get_tree`, `swaymsg -t get_binding_state`
- Atalho já usado? `rg -n 'bindsym \$mod\+x' ~/.dotfiles/home/.config/sway ~/.dotfiles/hosts/shadowtec-giratina`
