# Config do OpenCode (agente local)

`opencode.json` é JSON PURO de propósito: o RTK (plugins/rtk.ts) lê as permissões daqui pra decidir se pode
reescrever um comando, e o leitor dele não aceita comentários (com um `//` ele ignora as permissões e reescreve
tudo — `git push` viraria `rtk git push` e escaparia do deny). Explicações ficam aqui.

- **providers.llama**: llama-server local (roteador). Apelidos → seções do ~/.dotfiles/apps/llm/modelos.ini:
  `qwen35b` = "Qwen3.6 35B pesado" (agente, 64k, visão), `qwen9b` = "Qwen3.5 9B" (48k, visão), `qwen8b`.
  Raciocínio desligado por padrão (o Qwen raciocina em inglês, ~10x tokens); variante `#pensar` liga com
  teto de 2048 tokens (`thinking_budget_tokens`).
- **agents.plan**: modo planejar (Tab) usa `qwen35b#pensar`. Subagente `pensador` (agents/pensador.md) idem.
- **tool_output**: ≤ 400 linhas / 16 KiB por saída (~4k tokens); íntegra salva em arquivo.
  O read (fixo em 2000 linhas no código) é limitado a 400 pelo plugin `plugins/leitura-curta.ts`.
- **compaction**: buffer 20% (compacta em ~52k no 35B / ~39k no 9B), keep 8000, sem resumo em segundo plano.
- **instructions**: `.opencode/notas.md` do projeto = memória curta (máx. 40 linhas).
- **mcp.web**: SearXNG local + mcp-searxng em 127.0.0.1:3010 (token em ~/.config/llm/mcp-token, fora do git).
- **permissions**: vale a ÚLTIMA regra que casar. allow = leitura/diagnóstico; ask = editar/rodar/ler página;
  deny = sudo, rm -r, git push, docker, pacman -S/-R, llm.sh, modo-jogo.sh, sed -i em ~/.config, segredos.
  Regras `rtk ...` (allow) existem porque o RTK só reescreve quando o veredito não muda. Os denies também são
  espelhados na forma `rtk ...` (2ª camada, caso o RTK um dia não leia esta config). NUNCA liberar `rtk *`
  (`rtk proxy <cmd>` roda qualquer coisa). websearch embutido negado (usa serviços pagos externos); `execute`
  (modo código do MCP) negado pra modelo pequeno.
- A barreira real é o bubblewrap do `ia.sh` (sem docker.sock, sem ~/.ssh, sem D-Bus, sistema só leitura).
