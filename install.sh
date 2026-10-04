#!/usr/bin/env bash
#
# install.sh — dotfiles "Shadow Materia" para Sway
#
# Uso: ./install.sh [--packages] [--yes] [--host NOME]
#   --packages   instala os pacotes de packages/pacman.txt e packages/aur.txt
#   --yes        não pergunta nada (pra rodar de outro script)
#   --host NOME  força o perfil de hosts/NOME (padrão: hostname da máquina)
#
# Configs viram symlinks pro repo (editar no repo = editar no sistema).
# O que já existir no $HOME vai pra ~/.dotfiles-backup-<data>/ antes.
#
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(cat /etc/hostname 2>/dev/null || uname -n)"
DO_PACKAGES=false
YES=false
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
fail() { echo -e "${RED}[X]${NC} $*"; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --packages) DO_PACKAGES=true ;;
        --yes|-y)   YES=true ;;
        --host)     HOST="${2:?--host precisa de um nome}"; shift ;;
        -h|--help)  sed -n '3,12p' "$0"; exit 0 ;;
        *)          fail "Opção desconhecida: $1" ;;
    esac
    shift
done

[[ $EUID -ne 0 ]] || fail "Rode como o seu usuário, não como root."

confirm() {
    $YES && return 0
    local r; read -rp "$1 [s/N] " r
    [[ "${r,,}" == "s" ]]
}

# Lista de pacotes sem comentários/linhas vazias
pkglist() { sed -e 's/#.*//' "$1" | tr -s ' \t' '\n' | sed '/^$/d'; }

# ------------------------------------------------------------------
# Pacotes (opcional)
# ------------------------------------------------------------------
if $DO_PACKAGES; then
    NOCONFIRM=()
    $YES && NOCONFIRM=(--noconfirm)
    log "Instalando pacotes oficiais..."
    mapfile -t PKGS < <(pkglist "$DOT/packages/pacman.txt")
    sudo pacman -S --needed "${NOCONFIRM[@]}" "${PKGS[@]}"
    if command -v paru &>/dev/null; then
        log "Instalando pacotes do AUR..."
        mapfile -t AUR < <(pkglist "$DOT/packages/aur.txt")
        paru -S --needed "${NOCONFIRM[@]}" "${AUR[@]}"
    else
        warn "paru não encontrado — pule ou instale à mão: $(pkglist "$DOT/packages/aur.txt" | xargs)"
    fi
fi
# ------------------------------------------------------------------
# Symlinks
# ------------------------------------------------------------------
backup() {
    local dst="$1"
    mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
    mv "$dst" "$BACKUP/${dst#"$HOME"/}"
}

link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        return 0
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        backup "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
}

log "Ligando configs em $HOME..."
count=0
while IFS= read -r -d '' f; do
    rel="${f#./}"
    case "$rel" in
        *.in) continue ;;          # templates: tratados abaixo
    esac
    link "$DOT/home/$rel" "$HOME/$rel"
    count=$((count + 1))
done < <(cd "$DOT/home" && find . \( -type f -o -type l \) -print0)
ok "$count arquivos ligados."

# Templates (*.in): precisam do caminho real do $HOME, então são copiados
while IFS= read -r -d '' f; do
    rel="${f#./}"; dst="$HOME/${rel%.in}"
    tmp="$(mktemp)"
    sed "s|@HOME@|$HOME|g" "$DOT/home/$rel" > "$tmp"
    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ ! -L "$dst" ]] && cmp -s "$tmp" "$dst"; then rm -f "$tmp"; continue; fi
        backup "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    mv "$tmp" "$dst"
done < <(cd "$DOT/home" && find . -type f -name '*.in' -print0)

# ------------------------------------------------------------------
# Perfil da máquina (hosts/<hostname>)
# ------------------------------------------------------------------
HOSTDIR="$DOT/hosts/$HOST"
if [[ ! -d "$HOSTDIR" ]]; then
    warn "Sem perfil em hosts/$HOST — usando hosts/default."
    HOSTDIR="$DOT/hosts/default"
fi
link "$HOSTDIR/sway.conf" "$HOME/.config/sway/config.d/90-host.conf"
link "$HOSTDIR/ghostty"   "$HOME/.config/ghostty/host"
link "$HOSTDIR/waybar.css" "$HOME/.config/waybar/host.css"
ok "Perfil de máquina: $(basename "$HOSTDIR")"

# ------------------------------------------------------------------
# Gancho do git: todo 'git pull' que trouxer mudanças roda o install.sh
# de novo (--yes), então arquivos novos ganham link sozinhos.
# ------------------------------------------------------------------
if [[ -d "$DOT/.git/hooks" ]]; then
    cat > "$DOT/.git/hooks/post-merge" <<HOOK
#!/bin/sh
# Gerado pelo install.sh — liga arquivos novos depois de 'git pull'
exec "$DOT/install.sh" --yes --host "$HOST"
HOOK
    chmod +x "$DOT/.git/hooks/post-merge"
fi

# ------------------------------------------------------------------
# Extras (cada um só roda se a ferramenta existir)
# ------------------------------------------------------------------
command -v fc-cache &>/dev/null && fc-cache -f >/dev/null && ok "Cache de fontes atualizado."

if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update && ok "Pastas do usuário (Imagens, Documentos...) criadas."
fi

# Agente SSH do gnome-keyring
if systemctl --user show-environment &>/dev/null; then
    systemctl --user enable gcr-ssh-agent.socket &>/dev/null \
        && ok "gcr-ssh-agent.socket habilitado." \
        || warn "Não consegui habilitar gcr-ssh-agent.socket (gcr instalado?)."
else
    warn "Sem sessão systemd --user: habilite depois com 'systemctl --user enable gcr-ssh-agent.socket'."
fi

# Pastas azuis no Papirus (mexe em /usr/share/icons → precisa de sudo)
papirus_azul() {
    [[ "$(readlink -f /usr/share/icons/Papirus-Dark/64x64/places/folder.svg 2>/dev/null)" == *folder-blue* ]]
}
if command -v papirus-folders &>/dev/null && ! papirus_azul; then
    if sudo -n true 2>/dev/null || ! $YES; then
        sudo papirus-folders -C blue --theme Papirus-Dark >/dev/null && ok "Papirus: pastas azuis."
    else
        warn "Rode depois: sudo papirus-folders -C blue --theme Papirus-Dark"
    fi
fi

# zsh como shell padrão
if command -v zsh &>/dev/null && [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
    if ! $YES && confirm "Trocar o shell padrão para zsh?"; then
        chsh -s "$(command -v zsh)"
    fi
fi

[[ -d "$BACKUP" ]] && warn "Arquivos antigos salvos em: $BACKUP"
ok "Dotfiles instalados. Faça logout/login (ou \$mod+Shift+c no sway)."
