#!/usr/bin/env bash
# ia — agente local estilo Claude Code (OpenCode v2 + modelos do llama-server), isolado em bubblewrap.
#   ia                  abre o agente na pasta atual (modelo padrão: Qwen3.6 35B)
#   ia -m llama/qwen9b  outro modelo (qwen35b | qwen35b#rapido | qwen9b | qwen9b#pensar | qwen8b)
#   ia run "pedido"     modo não interativo
# Sobe o LLM se precisar (nunca no modo jogo) e derruba ao sair, se foi ele que subiu e o Chat local
# não estiver aberto. Config, skills e regras: ~/.dotfiles/home/.config/opencode.
#
# Sandbox (a barreira real; as permissões do OpenCode são só a 1ª camada):
#   - sistema todo só leitura; graváveis: pasta atual, ~/.dotfiles, ~/Documentos, ~/Claudio, /tmp
#   - sem socket do Docker (grupo docker = root), sem ~/.ssh/~/.gnupg/segredos, sem D-Bus da sessão
#     (daria pra escapar via systemd-run); só o socket do Wayland (colar imagem, grim)
#   - IA_SEM_SANDBOX=1 ia   roda sem isolamento (use só se souber o porquê)
set -euo pipefail
dir="$(dirname "$(readlink -f "$0")")"
llm="$dir/llm.sh"
run="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [[ -e "$run/modo-jogo" ]]; then echo "Modo jogo ligado: o LLM só roda fora do jogo." >&2; exit 1; fi
command -v opencode >/dev/null || { echo "opencode não instalado (~/.local/bin/opencode)" >&2; exit 1; }

subiu=0
if ! curl -sf http://127.0.0.1:8080/health >/dev/null; then
  echo "Subindo o LLM local…" >&2
  "$llm" subir >/dev/null && subiu=1
fi
encerrar() {
  if (( subiu )) && ! pgrep -f -- "--user-data-dir=$HOME/.local/share/llm/chat-app" >/dev/null; then
    "$llm" parar >/dev/null 2>&1 || true
  fi
}
trap encerrar EXIT

export OPENCODE_DISABLE_CLAUDE_CODE=1      # não ler ~/.claude (instruções e skills do Claude Code)
export OPENCODE_DISABLE_AUTOUPDATE=1
export OPENCODE_DISABLE_MODELS_FETCH=1     # nada de catálogo online
export OPENCODE_DISABLE_FREE_MODELS=1      # nada de modelo de nuvem

if [[ "${IA_SEM_SANDBOX:-0}" == 1 ]]; then opencode --standalone "$@"; exit; fi

mkdir -p ~/.local/share/opencode ~/.local/state/opencode ~/.cache/opencode ~/Claudio ~/Documentos
wl="${WAYLAND_DISPLAY:-wayland-1}"
args=(
  --ro-bind / / --dev /dev --proc /proc
  --bind /tmp /tmp
  --tmpfs /run --ro-bind /run/systemd/resolve /run/systemd/resolve
  --dir "$run" --bind "$run/$wl" "$run/$wl"
  --tmpfs "$HOME/.ssh" --tmpfs "$HOME/.gnupg" --tmpfs "$HOME/.docker"
  --tmpfs "$HOME/.config/restic" --tmpfs "$HOME/.config/rclone" --tmpfs "$HOME/.config/controle-tv"
  --tmpfs "$HOME/.local/share/keyrings"
  --bind "$HOME/.dotfiles" "$HOME/.dotfiles"
  --bind "$HOME/Documentos" "$HOME/Documentos"
  --bind "$HOME/Claudio" "$HOME/Claudio"
  --bind "$HOME/.local/share/opencode" "$HOME/.local/share/opencode"
  --bind "$HOME/.local/state/opencode" "$HOME/.local/state/opencode"
  --bind "$HOME/.cache/opencode" "$HOME/.cache/opencode"
  --tmpfs "$HOME/.config/llm" --ro-bind "$HOME/.config/llm/mcp-token" "$HOME/.config/llm/mcp-token"
)
case "$PWD" in "$HOME"|/) ;; *) args+=(--bind "$PWD" "$PWD") ;; esac
bwrap "${args[@]}" \
  --unsetenv DBUS_SESSION_BUS_ADDRESS --unsetenv SWAYSOCK \
  --unshare-pid --unshare-ipc --unshare-uts --die-with-parent \
  --chdir "$PWD" opencode --standalone "$@"
