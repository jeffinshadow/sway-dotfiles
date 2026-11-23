---
name: jogos-config
description: Config de jogo: CSP / ext_config.ini, configs do Assetto Corsa, MangoHud, Proton e opções de inicialização do Steam, ETS2.
---
# Configs de jogos

## Caminhos
- AC (CSP padrão): /mnt/jogos/Steam/steamapps/common/assettocorsa/extension/config/
- AC (do usuário, prefixo Proton): /mnt/jogos/Steam/steamapps/compatdata/244210/pfx/drive_c/users/steamuser/Documents/Assetto Corsa/cfg/
  - overrides do CSP: .../cfg/extension/
- Por carro: content/cars/<carro>/extension/ext_config.ini; por skin: skins/<skin>/ext_config.ini
- ETS2: ~/.local/share/Euro Truck Simulator 2/config.cfg
- MangoHud: ~/.dotfiles/home/.config/MangoHud/MangoHud.conf (opção de inicialização: `mangohud %command%`)
- Proton: proton-cachyos-slr (sistema) e GE-Proton em ~/.steam/root/compatibilitytools.d

## Regras
1. Jogo FECHADO antes de editar: `pgrep -af steam_app_` precisa vir vazio (o jogo regrava ao sair).
2. Backup antes: `cp arquivo arquivo.bak-$(date +%F)`.
3. Edite só a chave pedida; mantenha o formato INI ([SEÇÃO], CHAVE=valor) e comentários.
4. Não edite localconfig.vdf com o Steam aberto.
5. Não sabe o que uma chave faz? Procure no próprio arquivo padrão do CSP (tem comentários) ou na web.
