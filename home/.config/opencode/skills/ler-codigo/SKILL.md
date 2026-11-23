---
name: ler-codigo
description: Explorar ou entender código/config sem abrir arquivo inteiro (esboço com linhas + leitura por faixa). Use antes de ler qualquer arquivo com mais de 300 linhas ou pasta desconhecida.
---
# Ler código gastando pouco contexto

1. Achar onde está: `rg -n 'termo' pasta` (ou glob). Projeto desconhecido: `esboco pasta` (arquivos e tamanhos).
2. Mapa do arquivo: `esboco arquivo` → funções/classes/seções com número de linha (Python mostra início-fim).
3. Ler só o trecho: read com offset=início e limit=(fim-início+5). Nunca read sem offset/limit em arquivo >300 linhas.
4. Quem chama / onde é usado: `rg -n -w nome pasta`.
5. Contexto em volta de um achado: `rg -n -C 5 'termo' arquivo`.
6. Editar: leia só o trecho que vai mudar e use edit com o texto exato desse trecho.

A dica "prefer one larger read" da ferramenta read NÃO vale aqui: o contexto é curto.
