// Leitura curta: limita o que read e grep despejam no contexto (janela de 48-64k).
// - read: o OpenCode lê até 2000 linhas / 50 KiB por chamada (~12k tokens) e não dá pra configurar;
//   aqui vira no máximo 400 linhas (a ferramenta avisa "Continue reading with offset: N").
// - grep: padrão de 100 resultados (um grep no repositório inteiro chegou a ~6k tokens); aqui, 40.
const LIMITES: Record<string, number> = { read: 400, grep: 40 }

export default {
  id: "local.leitura-curta",
  async setup(ctx: any) {
    await ctx?.tool?.hook?.("execute.before", (e: any) => {
      const max = LIMITES[e?.tool]
      if (!max || !e.input || typeof e.input !== "object") return
      if (e.input.limit === undefined || e.input.limit === null || e.input.limit > max) e.input.limit = max
    })
  },
}
