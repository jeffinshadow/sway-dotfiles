---
name: llm-local
description: Perguntas sobre o próprio LLM local, modelos, modelos.ini, llama-server, Chat local, OpenCode.
---
# O próprio LLM local

- Arquivos: ~/.dotfiles/apps/llm/{llm.sh,compose.yaml,modelos.ini,chat/,ia.sh} (ia = interface gráfica pt-BR; ia tui; ia run)
- Servidor: llama.cpp em modo roteador (um modelo por vez), http://127.0.0.1:8080; `curl -s 127.0.0.1:8080/models`
- Modelos: "Qwen3.6 35B pesado" (agente, 64k, visão), "Qwen3.5 9B" (rápido, 48k, visão), "Qwen3 8B rápido"
- Pesquisa web: SearXNG (127.0.0.1:8888) + MCP (127.0.0.1:3010), sobem junto com o LLM.
- Você roda NELE: não pare o container nem rode llm.sh. Mudanças no modelos.ini só valem quando o usuário reinicia.
- NUNCA `ubatch-size 4096` com `spec-type ngram-mod` (trava o servidor).
- Regras do usuário: o LLM só roda quando ele chama e nunca no modo jogo.
