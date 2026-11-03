#!/usr/bin/env bash
# Gera a logo da shadowtec em blocos (▀▄▌▐▖▗▘▝▚▞▙▛▜▟█) pro fastfetch, a partir
# do SVG do waybar. Cada caractere = 2x2 "pixels" (meios-blocos), com a
# proporção de célula do terminal (1:2).
# Uso: tools/shadowtec-ascii.sh [colunas] [linhas] [saída]   (padrão 34 x 17)
# As linhas vão marcadas de $1 a $9 de cima pra baixo: com as 9 cores no
# config.jsonc vira degradê (cores iguais = cor única).
# Saída padrão: home/.config/fastfetch/shadowtec.txt (precisa de ImageMagick e python3)
set -euo pipefail
cd "$(dirname "$0")/.."
COLS=${1:-34} ROWS=${2:-17}
SVG=home/.config/waybar/shadowtec.svg
OUT=${3:-home/.config/fastfetch/shadowtec.txt}
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
magick -background none -density 1200 "$SVG" -trim +repage -alpha extract \
    -resize "$((COLS * 2))x$((ROWS * 2))!" -depth 8 "gray:$tmp"
python3 - "$tmp" "$COLS" "$ROWS" "$OUT" <<'PY'
import sys
raw, cols, rows, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
b = open(raw, 'rb').read(); W = cols * 2
Q = ' ▘▝▀▖▌▞▛▗▚▐▜▄▙▟█'          # índice: TL=1 TR=2 BL=4 BR=8
on = lambda x, y: b[y * W + x] > 110
linhas = []
for y in range(0, rows * 2, 2):
    linhas.append(''.join(Q[on(x, y) | on(x+1, y) << 1 | on(x, y+1) << 2 | on(x+1, y+1) << 3]
                          for x in range(0, W, 2)).rstrip())
while linhas and not linhas[-1]: linhas.pop()
n = len(linhas)   # $1..$9: faixa de cor de cada linha (degradê no config.jsonc)
open(out, 'w').write(''.join(f'${1 + i * 9 // n}{l}\n' for i, l in enumerate(linhas)))
print(f"ok: {out} ({cols}x{len(linhas)})")
PY
