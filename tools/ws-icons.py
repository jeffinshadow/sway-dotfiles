#!/usr/bin/env python3
"""Gera os ícones fixos das workspaces (SVG) a partir da Symbols Nerd Font.

O waybar não tem ícone pra workspace vazia; o style.css mostra estes SVGs
como fundo do botão com a classe .empty. O GTK3 rasteriza o SVG no tamanho
do arquivo e depois escala, então sai um arquivo por tamanho: 16 px (barra
base) e 21 px (tela do notebook, eDP-1).
Saída: home/.config/waybar/ws/<n>-<px>.svg

Num container (precisa de fonttools e da fonte):
  docker run --rm -v "$PWD":/w -v /usr/share/fonts/TTF:/fonts:ro -w /w \
    python:3.12-slim sh -c 'pip install -q fonttools && python tools/ws-icons.py'
"""
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

RAIZ = Path(__file__).resolve().parent.parent
FONTE = Path("/fonts/SymbolsNerdFont-Regular.ttf")
SAIDA = RAIZ / "home/.config/waybar/ws"
COR = "#F0EDEE"
TAMANHOS = (16, 21)
ICONES = {   # mesmos da tabela do 40-rules.conf
    1: 0xF018D,   # terminal
    2: 0xF0239,   # web
    3: 0xF0B79,   # chat
    4: 0xF02B4,   # jogos
    5: 0xF03D8,   # design
    6: 0xF075A,   # mídia
    7: 0xF024B,   # arquivos
    8: 0xF0219,   # documentos
    9: 0xF01A7,   # livre (cubo vazado)
    10: 0xF0493,  # sistema
}

font = TTFont(FONTE)
cmap, gs = font.getBestCmap(), font.getGlyphSet()
SAIDA.mkdir(parents=True, exist_ok=True)
for ws, cp in ICONES.items():
    g = gs[cmap[cp]]
    bp = BoundsPen(gs); g.draw(bp)
    x0, y0, x1, y1 = bp.bounds
    lado = max(x1 - x0, y1 - y0)
    # centra num quadrado e vira o y (fonte: pra cima; SVG: pra baixo)
    dx = (lado - (x1 - x0)) / 2 - x0
    dy = (lado - (y1 - y0)) / 2 + y1
    sp = SVGPathPen(gs)
    g.draw(TransformPen(sp, (1, 0, 0, -1, dx, dy)))
    for px in TAMANHOS:
        (SAIDA / f"{ws}-{px}.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {lado:g} {lado:g}" '
            f'width="{px}" height="{px}"><path fill="{COR}" d="{sp.getCommands()}"/></svg>\n')
print(f"ok: {len(ICONES) * len(TAMANHOS)} SVGs em {SAIDA.relative_to(RAIZ)}")
