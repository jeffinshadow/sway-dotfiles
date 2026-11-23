---
name: assetto-corsa-skin
description: Skin/pintura do Assetto Corsa, texturas .dds, projeto Shadowtec 331 do 180SX, kn5, mapa UV, livery.
---
# Skin do Assetto Corsa (projeto Shadowtec 331)

Projeto: ~/Documentos/skin-180sx-shadowtec (leia o README.md primeiro: mapa UV, layout e decisões aprovadas).
Carro: /mnt/jogos/Steam/steamapps/common/assettocorsa/content/cars/dakuside_180sx_1JZ
Skin instalada: .../dakuside_180sx_1JZ/skins/Shadowtec 331

## Comandos
- Gerar texturas: `python3 src/build.py` (saída em build/)
- Gerar + converter pra DDS + instalar no jogo: `python3 src/build.py --install`
- Inspecionar DDS: `magick identify arquivo.dds`
- Converter: `magick in.dds out.png`; PNG→DDS com mipmaps:
  `magick in.png -define dds:compression=dxt5 -define dds:mipmaps=14 out.dds` (dxt1 sem alfa, none = sem perda)
- Python: numpy, Pillow (lê BC1–BC7), scipy disponíveis. BC7 não é gravado por magick/Pillow.

## Regras do usuário
- Antes de mudar o gerador, copie a versão atual (build/build_vN.py).
- Em revisão: anote os pedidos em build/revisao_vN/NOTAS.md ANTES de aplicar; não aplique até o usuário
  dizer que terminou de listar.
- Partes já aprovadas (laterais, saia): não mexer sem pedido.
- `--install` só com o Assetto Corsa FECHADO (`pgrep -af steam_app_244210` vazio). Peça pra fechar.
- Prints pra conferir: o usuário abre o showroom; print com `grim -o DP-1 /tmp/ac.png` e você olha a imagem.
