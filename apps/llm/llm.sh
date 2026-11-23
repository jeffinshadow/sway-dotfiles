#!/usr/bin/env bash
# llm.sh abrir|parar|estado — LLM local sob demanda (compose.yaml ao lado).
#   abrir: sobe o container (se preciso), espera carregar o modelo e abre a interface web
#   parar: derruba o container e libera a VRAM
set -euo pipefail
dir="$(dirname "$(readlink -f "$0")")"
url="http://127.0.0.1:8080"
dc() { docker compose -f "$dir/compose.yaml" -p llm "$@"; }

case "${1:-abrir}" in
  abrir)
    if ! curl -sf "$url/health" >/dev/null; then
      if [[ ! -f "$HOME/.local/share/llm/models/Qwen3-8B-Q4_K_M.gguf" ]]; then
        notify-send -a llm -u critical "LLM local" "O modelo ainda não foi baixado (~/.local/share/llm/models)."; exit 1
      fi
      notify-send -a llm -t 4000 -i applications-science "LLM local" "Carregando o Qwen3 8B na GPU…"
      dc up -d >/dev/null 2>&1
      for _ in $(seq 1 90); do curl -sf "$url/health" >/dev/null && break; sleep 1; done
      curl -sf "$url/health" >/dev/null || { notify-send -a llm -u critical "LLM local" "Não subiu: docker logs llm"; exit 1; }
    fi
    xdg-open "$url" >/dev/null 2>&1 & ;;
  parar)
    dc down >/dev/null 2>&1
    notify-send -a llm -t 3000 -i applications-science "LLM local" "Parado (VRAM liberada)." ;;
  estado) curl -sf "$url/health" >/dev/null && echo rodando || echo parado ;;
  *) echo "uso: $0 abrir|parar|estado" >&2; exit 2 ;;
esac
