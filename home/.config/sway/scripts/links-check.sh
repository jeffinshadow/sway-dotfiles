#!/usr/bin/env bash
# links-check.sh — avisa se algum arquivo do repo de dotfiles ainda não tem
# symlink no $HOME. O install.sh liga arquivo por arquivo: um script novo
# criado no repo (sem 'git pull', que roda o install sozinho) fica sem link
# e o atalho que o chama não funciona. Roda a cada reload do sway.
set -euo pipefail

cfg=$(readlink -f ~/.config/sway/config) || exit 0
dot=${cfg%/home/.config/sway/config}
[[ "$dot" != "$cfg" && -d "$dot/home" ]] || exit 0

faltam=()
while IFS= read -r -d '' f; do
    rel=${f#"$dot/home/"}
    [[ "$(readlink -f "$HOME/$rel" 2>/dev/null)" == "$f" ]] || faltam+=("$rel")
done < <(find "$dot/home" -type f ! -name '*.in' -print0)

(( ${#faltam[@]} )) || exit 0
lista=$(printf '%s\n' "${faltam[@]:0:5}")
(( ${#faltam[@]} > 5 )) && lista+=$'\n'"… e mais $(( ${#faltam[@]} - 5 ))"
notify-send -a dotfiles -u critical -i dialog-warning \
    "${#faltam[@]} arquivo(s) dos dotfiles sem link" \
    "$lista"$'\n'"Rode: $dot/install.sh"
