# Shadow Materia — Sway

Dotfiles do Sway com a paleta **Shadow Materia**: o mesmo visual do rice KDE
([chinesedemocracy-dotfiles](https://github.com/jeffinshadow/chinesedemocracy-dotfiles))
e do GTK antigo do i3, num ambiente Wayland com apps GTK.

Servem pra qualquer máquina. O que muda entre elas fica em `hosts/<hostname>/`.

| Máquina | Perfil |
|---|---|
| `shadowtec-latios` | Latitude 7280: escala 1.0 com texto 1.1× (igual à giratina), waybar maior, kanshi, tampa, suspensão |
| `shadowtec-giratina` | Desktop/servidor 24/7: monitor 1080p a 100 Hz (atrás de um KVM), subpixel RGB, ghostty 10, sem suspensão, mouse flat |
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
| Barra | Waybar: fundo transparente, só as pílulas `#1A1A1C` (raio 8) sobre o papel de parede; encostada no topo; relógio à direita; CPU/memória/temperatura/disco no grupo "sistema" (abre com o mouse, fica âmbar/vermelho em alerta) |
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
| Temas de apps | Paleta Shadow Materia também no btop, vim (`colorscheme shadow-materia`), GNOME Text Editor, foot, Vesktop/Discord, fzf e tmux. Firefox (`apps/firefox`: userChrome/userContent, ligados em cada perfil) e Chromium (extensão de tema via `chromium-flags.conf`) também. LibreOffice, VLC e afins seguem o GTK/qt6ct |

## Paleta

Shadow Materia híbrida (Material 3): referência completa, inclusive o tema
claro, em [PALETA-HIBRIDA.md](PALETA-HIBRIDA.md). Resumo do escuro:

| Cor | Hex | Uso |
|---|---|---|
| Fundo mais fundo | `#0C0D0E` | Atrás de tudo |
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
| `Super+Enter` | Terminal · na latios, `Super+Shift+Enter` abre SSH na giratina |
| `Super+d` | Rofi (apps) · `Super+Tab` janelas |
| `Super+n` / `Super+b` | Nautilus / Firefox |
| `Super+q` | Fechar janela |
| `Super+j k l ç` (ou setas) | Foco · `+Shift` move |
| `Super+h` / `Super+Shift+v` | Divisão horizontal / vertical |
| `Super+s` / `w` / `e` | Empilhado / abas / alterna divisão |
| `Super+Shift+Espaço` ou `Super+Shift+f` | Flutuante ↔ lado a lado (flutuante abre a 65%×70%, centralizada, com aviso) |
| `Super+r` | Modo redimensionar (passos de 40px; `Shift` = 10px) |
| `Super+v` | Histórico da área de transferência (nwg-clipman, como o Win+V) |
| `Super+Shift+t` / `Super+Shift+p` | Copiar texto de uma área (OCR) / cor de um pixel (#hex) |
| `Super+p` | Monitor externo: estender ↔ espelhar |
| `Super+x` | Bloquear |
| `Super+Shift+e` | Menu de energia (sair/reiniciar/desligar pedem confirmação) |
| `Super+.` / `Super+Shift+.` | Dispensar / reabrir notificação |
| `Super+Shift+n` | Não perturbe (sino na barra) |
| `Print` / `Ctrl+Print` / `Shift+Print` | Captura: tela / área (swappy) / janela |
| `Super+Print` / `Super+Shift+Print` | Gravar área / tela (de novo: parar; REC na barra) |
| `Super+1…0` | Workspace (apertar a atual volta pra anterior). Fixas: 1 terminal · 2 Firefox · 3 Chromium/Vesktop · 4 Steam/jogos |

## Nova máquina

```bash
cp -r hosts/default hosts/<hostname>
$EDITOR hosts/<hostname>/sway.conf    # monitores, escala de texto, energia
$EDITOR hosts/<hostname>/waybar.css   # tamanho da barra
cp foto.png hosts/<hostname>/wallpaper.png   # opcional (sem ele: shadow-principal)
$EDITOR hosts/<hostname>/environment.conf    # opcional: variáveis de sessão (environment.d)
$EDITOR hosts/<hostname>/packages.txt        # opcional: pacotes só dessa máquina
./install.sh
```
