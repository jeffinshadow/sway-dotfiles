# Shadow Materia — Sway

Dotfiles do Sway com a paleta **Shadow Materia**: o mesmo visual do rice KDE
([chinesedemocracy-dotfiles](https://github.com/jeffinshadow/chinesedemocracy-dotfiles))
e do GTK antigo do i3, num ambiente Wayland com apps GTK.

Servem pra qualquer máquina. O que muda entre elas fica em `hosts/<hostname>/`.

| Máquina | Perfil |
|---|---|
| `shadowtec-latios` | Latitude 7280: escala 1.0 com texto 1.15×, waybar maior, kanshi, tampa, suspensão |
| `shadowtec-giratina` | Desktop/servidor 24/7: monitor 1080p a 100 Hz (atrás de um KVM), sem suspensão, mouse flat |
| qualquer outra | `hosts/default` |

## Instalação

```bash
git clone https://github.com/jeffinshadow/sway-dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh --packages     # instala pacotes + liga as configs
./install.sh                # só liga as configs
./install.sh --host NOME    # força um perfil de hosts/
```

As configs viram **symlinks** pro repo: editou aqui, mudou no sistema.
Tudo o que já existia vai pra `~/.dotfiles-backup-<data>/`.
Rodar de novo é seguro.

## Componentes

| Papel | Escolha |
|---|---|
| Compositor | Sway (puro) |
| Barra | Waybar: pílulas `#1A1A1C` sobre `#0C0D0E`, raio 8 |
| Lançador | Rofi 2 (Wayland nativo), centralizado |
| Terminal | Ghostty: GTK4, imagens (protocolo kitty), Nerd Font |
| Arquivos | Nautilus |
| Notificações / OSD | mako / swayosd |
| Bloqueio | swaylock + swayidle |
| Login | greetd + tuigreet (configurado pelo deploy da máquina) |
| Tema GTK3 | adw-gtk3-dark + paleta em `gtk-3.0/gtk.css` |
| Tema GTK4 | libadwaita + paleta em `gtk-4.0/gtk.css` |
| Tema Qt | qt6ct + Fusion + paleta `ShadowMateria.conf` |
| Ícones / cursor | Papirus-Dark (pastas azuis) / Bibata Modern Ice |
| Fontes | Google Sans (UI) / Google Sans Code (mono) |
| Shell | zsh + starship + fastfetch |
| Multiplexador | tmux (abre/reanexa a sessão `main` sozinho em todo SSH) |

## Paleta

Shadow Materia híbrida (Material 3): referência completa, inclusive o tema
claro, em [PALETA-HIBRIDA.md](PALETA-HIBRIDA.md). Resumo do escuro:

| Cor | Hex | Uso |
|---|---|---|
| Fundo mais fundo | `#0C0D0E` | Barra |
| Fundo | `#131314` | Fundo de janela, terminal, rofi |
| Contêiner | `#1A1A1C` | Cards, campos, pílulas |
| Contêiner alto / mais alto | `#222324` / `#2C2C2D` | Menus, popovers / avisos, hover |
| Divisores | `#323235` / `#49494B` | Bordas inativas / bordas de campo |
| Primário | `#5294E2` | Foco, workspace ativa (texto sobre ele: `#0B0D10`) |
| Primário claro | `#8AB8F0` | Links, ícones ativos, cursor |
| Contêiner primário | `#183A61` | Seleção (sólida, sem transparência) |
| Texto / apagado | `#F0EDEE` / `#919093` | Corpo / rótulos |
| Status | `#F28B82` `#F2DA66` `#78CA9F` `#B98EFF` `#62C7E0` | Erro, aviso, ok, roxo, ciano |

## Atalhos principais

| Tecla | Ação |
|---|---|
| `Super+F1` ou botão direito no logo do Arch | Esta cola de atalhos (gerada do config) |
| `Super+Enter` | Terminal |
| `Super+d` | Rofi (apps) · `Super+Tab` janelas |
| `Super+n` / `Super+b` | Nautilus / Firefox |
| `Super+q` | Fechar janela |
| `Super+j k l ç` (ou setas) | Foco · `+Shift` move |
| `Super+h` / `Super+v` | Divisão horizontal / vertical |
| `Super+s` / `w` / `e` | Empilhado / abas / alterna divisão |
| `Super+r` | Modo redimensionar |
| `Super+Shift+v` | Histórico do clipboard |
| `Super+p` | Monitor externo: estender ↔ espelhar |
| `Super+x` | Bloquear |
| `Super+Shift+e` | Menu de energia |
| `Super+.` | Dispensar notificação |
| `Print` / `Ctrl+Print` / `Shift+Print` | Captura: tela / área (swappy) / janela |

## Nova máquina

```bash
cp -r hosts/default hosts/<hostname>
$EDITOR hosts/<hostname>/sway.conf    # monitores, escala de texto, energia
$EDITOR hosts/<hostname>/waybar.css   # tamanho da barra
cp foto.png hosts/<hostname>/wallpaper.png   # opcional (sem ele: shadow-principal)
./install.sh
```
