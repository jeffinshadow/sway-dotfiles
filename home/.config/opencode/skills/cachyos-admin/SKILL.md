---
name: cachyos-admin
description: Diagnóstico do sistema CachyOS/Arch: pacotes, atualizações, logs, serviços systemd, discos, GPU, erro do sistema.
---
# Administração do CachyOS (só diagnóstico; instalar é com o usuário)

## Leitura (pode rodar)
- Pacotes: `pacman -Qi x`, `pacman -Ql x`, `pacman -Qo /caminho`, `pacman -Ss termo`, `paru -Ss termo`
- Atualizações: `checkupdates`, `paru -Qua`
- Logs: `journalctl -b -p warning --no-pager | tail -100`; serviço: `journalctl --user -u nome -n 100 --no-pager`
- Serviços: `systemctl --user status nome`, `systemctl --failed`, `systemctl --user list-timers`
- Disco/memória: `df -h`, `lsblk`, `free -h`; GPU: `cat /sys/class/drm/card1/device/mem_info_vram_used`
- Serviços do usuário: backup-drive.timer, rp-backup-pull.timer (~/.config/systemd/user)

## Mudanças (NÃO execute; entregue o comando)
- Instalar: `sudo pacman -S pacote` ou `paru -S pacote`. Se for permanente, sugira adicionar em
  ~/.dotfiles/packages/pacman.txt, aur.txt ou ~/.dotfiles/hosts/shadowtec-giratina/packages.txt
- Serviço de sistema: `sudo systemctl ...` (usuário roda).
- Wiki: wiki.archlinux.org e wiki.cachyos.org são as melhores fontes.
