#!/usr/bin/env bash
# ia — agente local estilo Claude Code (OpenCode v2 + modelos do llama-server), isolado em bubblewrap.
#   ia                  interface gráfica EM PORTUGUÊS numa janela própria (servidor na pasta atual)
#   ia tui [opções]     interface de terminal (só existe em inglês)
#   ia run "pedido"     modo não interativo (ex.: ia run -m llama/qwen9b "...")
# Modelos: llama/qwen35b (padrão) | qwen35b#pensar | qwen9b | qwen9b#pensar | qwen8b
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

mkdir -p ~/.local/share/opencode ~/.local/state/opencode ~/.cache/opencode ~/.local/share/rtk ~/Claudio ~/Documentos
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
  --bind "$HOME/.local/share/rtk" "$HOME/.local/share/rtk"
  --tmpfs "$HOME/.config/llm" --ro-bind "$HOME/.config/llm/mcp-token" "$HOME/.config/llm/mcp-token"
  --unsetenv DBUS_SESSION_BUS_ADDRESS --unsetenv SWAYSOCK
  --unshare-pid --unshare-ipc --unshare-uts --die-with-parent
)
case "$PWD" in "$HOME"|/) ;; *) args+=(--bind "$PWD" "$PWD") ;; esac
isolado() {
  if [[ "${IA_SEM_SANDBOX:-0}" == 1 ]]; then "$@"; else bwrap "${args[@]}" --chdir "$PWD" "$@"; fi
}

case "${1:-}" in
  tui) shift; isolado opencode --standalone "$@" ;;
  run) isolado opencode --standalone "$@" ;;
  *)
    # interface gráfica (pt-BR): servidor isolado com senha aleatória só em 127.0.0.1; a janela
    # entra já logada (?auth_token, que a interface apaga da URL) e fechar a janela encerra tudo
    porta=4097
    if curl -s -o /dev/null 127.0.0.1:$porta 2>/dev/null; then
      notify-send -a llm "Agente local" "Já está aberto." 2>/dev/null; swaymsg -q '[title="OpenCode"] focus' 2>/dev/null; exit 0
    fi
    export OPENCODE_SERVER_PASSWORD="$(openssl rand -hex 24)"
    isolado opencode serve --hostname 127.0.0.1 --port $porta >"${XDG_STATE_HOME:-$HOME/.local/state}/opencode/ia-serve.log" 2>&1 &
    srv=$!
    for _ in $(seq 60); do curl -s -o /dev/null 127.0.0.1:$porta && break; sleep 0.25; done
    token="$(printf 'opencode:%s' "$OPENCODE_SERVER_PASSWORD" | base64 -w0)"
    unset OPENCODE_SERVER_PASSWORD
    chromium --user-data-dir="$HOME/.local/share/llm/agente-app" --app="http://127.0.0.1:$porta/?auth_token=$token" \
      --class=llm-agente --lang=pt-BR --disable-features=Translate --no-first-run --no-default-browser-check \
      >/dev/null 2>&1 || true
    kill "$srv" 2>/dev/null; wait "$srv" 2>/dev/null || true ;;
esac
