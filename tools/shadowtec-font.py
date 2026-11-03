#!/usr/bin/env python3
"""Gera a fonte "ShadowTec Symbols" (um glyph só: o dragão da shadowtec).

Serve pra usar a logo onde só cabe texto, como o tooltip do waybar
(<span font_family='ShadowTec Symbols'>\U00100000</span>).
Fonte: home/.config/waybar/shadowtec.svg (viewBox 32x32, um <path> com
transform). Saída: home/.local/share/fonts/ShadowTecSymbols.otf.

Precisa de fonttools. Sem Python no sistema, num container:
  docker run --rm -v "$PWD":/w -w /w python:3.12-slim \
    sh -c 'pip install -q fonttools && python tools/shadowtec-font.py'
"""
import re
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.svgLib.path import parse_path

RAIZ = Path(__file__).resolve().parent.parent
SVG = RAIZ / "home/.config/waybar/shadowtec.svg"
SAIDA = RAIZ / "home/.local/share/fonts/ShadowTecSymbols.otf"
CODEPOINT = 0x100000          # Unicode PUA-B: não colide com a Nerd Font
UPM, ASC, DESC = 1000, 800, 200
ALTURA = 900                  # altura do desenho em unidades (≈ altura das maiúsculas + um pouco)

svg = SVG.read_text()
d = re.search(r'\sd="([^"]+)"', svg).group(1)
a, b, c, dd, e, f = map(float, re.search(r'matrix\(([^)]+)\)', svg).group(1).split(","))

def desenhar(pen):
    # path → coordenadas do viewBox (transform do SVG) → unidades da fonte
    # (y do SVG cresce pra baixo; na fonte, pra cima)
    parse_path(d, TransformPen(pen, (a, b, c, dd, e, f)))

# medidas no espaço do viewBox
bp = BoundsPen(None)
desenhar(bp)
x0, y0, x1, y1 = bp.bounds
esc = ALTURA / (y1 - y0)
larg = round((x1 - x0) * esc)
margem = 40
base = -120                   # desce um pouco abaixo da linha de base, como um ícone

def desenhar_fonte(pen):
    t = TransformPen(pen, (esc, 0, 0, -esc, margem - x0 * esc, base + y1 * esc))
    desenhar(t)

cs = T2CharStringPen(larg + 2 * margem, None)
desenhar_fonte(cs)
charstring = cs.getCharString()
notdef = T2CharStringPen(500, None).getCharString()

fb = FontBuilder(UPM, isTTF=False)
fb.setupGlyphOrder([".notdef", "shadowtec"])
fb.setupCharacterMap({CODEPOINT: "shadowtec"})
fb.setupCFF("ShadowTecSymbols-Regular", {"FullName": "ShadowTec Symbols"},
            {".notdef": notdef, "shadowtec": charstring}, {})
fb.setupHorizontalMetrics({".notdef": (500, 0), "shadowtec": (larg + 2 * margem, margem)})
fb.setupHorizontalHeader(ascent=ASC, descent=-DESC)
fb.setupNameTable({"familyName": "ShadowTec Symbols", "styleName": "Regular"})
fb.setupOS2(sTypoAscender=ASC, sTypoDescender=-DESC, usWinAscent=ASC + 100, usWinDescent=DESC + 100)
fb.setupPost()
SAIDA.parent.mkdir(parents=True, exist_ok=True)
fb.save(SAIDA)
print(f"ok: {SAIDA.relative_to(RAIZ)}  (U+{CODEPOINT:X}, largura {larg + 2 * margem})")
