#!/usr/bin/env bash
# keybinds.sh — cola de atalhos no rofi, gerada a partir do config do sway.
# Só aparecem os atalhos documentados com "#:" (ver config.d/30-binds.conf).
set -euo pipefail
export LC_ALL=C.UTF-8   # gawk conta caracteres (não bytes) no alinhamento

conf="$HOME/.config/sway/config.d"

gawk '
function pretty(k) {
    gsub(/\$mod/, "Super", k)
    gsub(/\+/, " + ", k)
    gsub(/Return/, "Enter", k);   gsub(/ccedilla/, "ç", k)
    gsub(/period/, ".", k);       gsub(/minus/, "-", k)
    gsub(/space/, "Espaço", k);   gsub(/Print/, "PrtSc", k)
    gsub(/Left/, "←", k);  gsub(/Right/, "→", k)
    gsub(/Up/, "↑", k);    gsub(/Down/, "↓", k)
    return k
}
function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); return s }

/^[ \t]*#::/ {
    sub(/^[ \t]*#::[ \t]*/, "")
    printf "<span color=\"#5294e2\"><b>%s</b></span>\n", esc($0)
    next
}
/^[ \t]*#:/ {
    sub(/^[ \t]*#:[ \t]*/, ""); desc = $0; next
}
/^[ \t]*bindsym/ && desc != "" {
    key = ""
    for (i = 2; i <= NF; i++) if ($i !~ /^--/) { key = $i; break }
    if (index(desc, " | ")) {
        key  = substr(desc, 1, index(desc, " | ") - 1)
        desc = substr(desc, index(desc, " | ") + 3)
    } else {
        key = pretty(key)
    }
    pad = 34 - length(key); if (pad < 2) pad = 2
    printf "   <span font_family=\"monospace\" color=\"#8ab4f8\">%s%*s</span>%s\n", esc(key), pad, "", esc(desc)
    desc = ""
    next
}
' "$conf"/*.conf \
| rofi -dmenu -i -markup-rows -no-custom -p "Atalhos" \
       -theme-str 'window {width: 760px;} listview {lines: 18;}' \
       >/dev/null || true
