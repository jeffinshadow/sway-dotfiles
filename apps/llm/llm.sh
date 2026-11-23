#!/usr/bin/env bash
# llm.sh — LLM local sob demanda (llama.cpp em modo roteador; compose.yaml e modelos.ini ao lado).
#   abrir [modelo]   sobe o servidor e abre o Chat local (janela própria); FECHAR A JANELA DERRUBA
#                    o servidor e libera a VRAM. Se o chat já estiver aberto, só traz pra frente.
#   subir [modelo]   só o servidor (pra usar a API em http://127.0.0.1:8080/v1); derrubar com parar
#   parar            derruba e libera a VRAM (e a RAM do modelo pesado)
#   estado           "rodando: <modelo carregado>" ou "parado"
# Modelos (nomes = seções do modelos.ini): "Qwen3.5 9B" (padrão), "Qwen3 8B rápido", "Qwen3.6 35B pesado".
# Nunca sobe no modo jogo; o modo-jogo.sh derruba o LLM ao ligar.
set -euo pipefail
dir="$(dirname "$(readlink -f "$0")")"
url="http://127.0.0.1:8080"
perfil="$HOME/.local/share/llm/chat-app"          # perfil próprio do Chromium (conversas ficam aqui)
dc() { docker compose -f "$dir/compose.yaml" -p llm "$@"; }
aviso() { notify-send -a llm -t "${2:-4000}" -i applications-science "LLM local" "$1"; }

subir() {
  if [[ -e "${XDG_RUNTIME_DIR:-/tmp}/modo-jogo" ]]; then aviso "Modo jogo ligado: o LLM só roda fora do jogo."; exit 1; fi
  if ! curl -sf "$url/health" >/dev/null; then
    dc up -d >/dev/null 2>&1
    for _ in $(seq 1 60); do curl -sf "$url/health" >/dev/null && break; sleep 0.5; done
    curl -sf "$url/health" >/dev/null || { aviso "Não subiu: docker logs llm" 8000; exit 1; }
  fi
  if [[ -n "${1:-}" ]]; then        # pré-carrega o modelo pedido
    curl -sf "$url/models/load" -H 'Content-Type: application/json' -d "{\"model\":\"$1\"}" >/dev/null || true
  fi
}

case "${1:-abrir}" in
  abrir)
    if pgrep -f -- "--user-data-dir=$perfil" >/dev/null; then
      swaymsg -q '[title="Chat local$"] focus' 2>/dev/null; exit 0
    fi
    subir "${2:-}"
    mkdir -p "$perfil"
    # roda em primeiro plano: quando a janela fecha, o servidor desce
    chromium --user-data-dir="$perfil" --app="$url/" --class=llm-chat --lang=pt-BR \
      --no-first-run --no-default-browser-check >/dev/null 2>&1 || true
    dc down >/dev/null 2>&1; aviso "Chat fechado: LLM parado, VRAM liberada." 2500 ;;
  subir) subir "${2:-}" ;;
  parar) dc down >/dev/null 2>&1; aviso "Parado (VRAM liberada)." 3000 ;;
  estado)
    if curl -sf "$url/health" >/dev/null; then
      m=$(curl -sf "$url/models" | python3 -c "import json,sys;print(', '.join(x['id'] for x in json.load(sys.stdin)['data'] if x['status']['value'] in ('loaded','loading')) or 'nenhum modelo carregado')" 2>/dev/null)
      echo "rodando: ${m:-?}"
    else echo parado; fi ;;
  *) echo "uso: $0 abrir [modelo] | subir [modelo] | parar | estado" >&2; exit 2 ;;
esac
