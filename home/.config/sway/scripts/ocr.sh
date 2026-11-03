#!/usr/bin/env bash
# ocr.sh — seleciona uma área da tela, lê o texto (tesseract, português +
# inglês) e copia pra área de transferência. Pra console de VM, iDRAC/iLO,
# imagem de erro: o que não deixa selecionar texto.
set -uo pipefail
command -v tesseract >/dev/null || {
    notify-send -u critical "OCR" "tesseract não instalado (tesseract-data-por/eng)"; exit 1; }

geom=$(slurp) || exit 0   # Esc no slurp: sai quieto
# 2x maior e em cinza: o tesseract erra bem menos em texto de tela pequeno
texto=$(grim -g "$geom" - | magick - -colorspace gray -resize 200% png:- \
        | tesseract stdin stdout -l por+eng --psm 6 2>/dev/null | sed -e 's/[[:space:]]*$//' -e '/./,$!d')

if [[ -z ${texto//[[:space:]]/} ]]; then
    notify-send -i edit-find "OCR" "Nenhum texto encontrado na área."
    exit 0
fi
printf '%s' "$texto" | wl-copy
linhas=$(printf '%s\n' "$texto" | wc -l)
notify-send -i edit-copy "Texto copiado ($linhas linha(s))" "$(printf '%s' "$texto" | head -c 300)"
