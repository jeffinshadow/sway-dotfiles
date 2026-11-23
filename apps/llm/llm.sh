#!/usr/bin/env bash
# llm.sh abrir [padrao|rapido|pesado] | parar | estado — LLM local sob demanda (compose.yaml ao lado).
#   abrir: sobe o perfil (troca se outro estiver no ar), espera carregar e abre a interface web
#   parar: derruba o container e libera a VRAM (e a RAM do perfil pesado)
#
# Perfis, medidos na RX 9050 em 22/11/2026 (llama.cpp build 12627, Vulkan; desktop ocupa ~1,1 GB):
#   padrao  Qwen3.5-9B Q4_K_M, 32k   ~42 t/s; contexto quase não pesa (atenção híbrida); 7,1 GB VRAM
#   rapido  Qwen3-8B IQ4_XS, 24k     ~54 t/s em respostas curtas; cai mais com contexto longo
#   pesado  Qwen3.6-35B-A3B MoE, 32k ~19 t/s; especialistas na RAM (--n-cpu-moe 32, ~17 GB em
#           cache); o mais forte em código/agente. -t 12 (HT atrapalha); ub 2048. NUNCA ub 4096
#           com ngram-mod (trava o servidor).
# Comum: FA ligado, KV q8_0, --spec-type ngram-mod (4-6x ao reescrever arquivo/config, custo zero
# no resto), cache de prompt na RAM limitado a 2 GB, tool calling (--jinja), /v1 e /v1/messages.
set -euo pipefail
dir="$(dirname "$(readlink -f "$0")")"
url="http://127.0.0.1:8080"
modelos="$HOME/.local/share/llm/models"
atual="${XDG_RUNTIME_DIR:-/tmp}/llm-perfil"
dc() { docker compose -f "$dir/compose.yaml" -p llm "$@"; }
comum="-fa on -ctk q8_0 -ctv q8_0 --spec-type ngram-mod --cache-ram 2048 --jinja --host 0.0.0.0 --port 8080"

perfil() {
  case "$1" in
    padrao) arq=Qwen3.5-9B-Q4_K_M.gguf; nome="Qwen3.5 9B"
            args="-m /models/$arq --alias qwen3.5-9b -ngl 99 -c 32768 $comum" ;;
    rapido) arq=Qwen3-8B-IQ4_XS.gguf; nome="Qwen3 8B (rápido)"
            args="-m /models/$arq --alias qwen3-8b -ngl 99 -c 24576 $comum" ;;
    pesado) arq=Qwen3.6-35B-A3B-UD-IQ4_XS.gguf; nome="Qwen3.6 35B (pesado)"
            args="-m /models/$arq --alias qwen3.6-35b -ngl 99 --n-cpu-moe 32 -t 12 -b 2048 -ub 2048 -c 32768 $comum" ;;
    *) echo "perfil: padrao|rapido|pesado" >&2; exit 2 ;;
  esac
}

case "${1:-abrir}" in
  abrir)
    p="${2:-padrao}"; perfil "$p"
    if curl -sf "$url/health" >/dev/null && [[ "$(cat "$atual" 2>/dev/null)" == "$p" ]]; then
      xdg-open "$url" >/dev/null 2>&1 & exit 0
    fi
    [[ -f "$modelos/$arq" ]] || { notify-send -a llm -u critical "LLM local" "Modelo não encontrado: $arq"; exit 1; }
    notify-send -a llm -t 4000 -i applications-science "LLM local" "Carregando $nome…"
    LLM_ARGS="$args" dc up -d --force-recreate >/dev/null 2>&1
    echo "$p" > "$atual"
    for _ in $(seq 1 180); do curl -sf "$url/health" >/dev/null && break; sleep 1; done
    curl -sf "$url/health" >/dev/null || { notify-send -a llm -u critical "LLM local" "Não subiu: docker logs llm"; exit 1; }
    xdg-open "$url" >/dev/null 2>&1 & ;;
  parar)
    dc down >/dev/null 2>&1; rm -f "$atual"
    notify-send -a llm -t 3000 -i applications-science "LLM local" "Parado (VRAM liberada)." ;;
  estado) curl -sf "$url/health" >/dev/null && echo "rodando: $(cat "$atual" 2>/dev/null || echo ?)" || echo parado ;;
  *) echo "uso: $0 abrir [padrao|rapido|pesado] | parar | estado" >&2; exit 2 ;;
esac
