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
| Barra | Waybar: pílulas `#282828` sobre `#181818`, raio 6 |
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

| Cor | Hex | Uso |
|---|---|---|
| Base | `#181818` | Fundo de janela, barra, terminal |
| Superfície | `#282828` | Botões, cards, pílulas, popovers |
| Superfície 2 | `#333333` | Hover, bordas inativas |
| Destaque | `#5294e2` | Seleção, foco, workspace ativa |
| Destaque claro | `#8ab4f8` | Texto/links em destaque, cursor |
| Texto | `#dedede` | Corpo |
| Semânticas | `#f28b82` `#fdd663` `#81c995` `#c58af9` | Erro, aviso, ok, roxo |

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
./install.sh
```
