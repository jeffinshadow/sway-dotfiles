#!/usr/bin/env bash
# Containers rodando pro waybar. Sem docker instalado não imprime nada
# (o módulo some). Algum unhealthy/reiniciando → classe warning.
command -v docker &>/dev/null || exit 0
systemctl is-active -q docker.service || {
    echo '{"text":"󰡨 off","class":"critical","tooltip":"docker.service parado"}'; exit 0; }

mapfile -t linhas < <(docker ps --format '{{.Names}}  {{.Status}}' 2>/dev/null)
class=normal
for l in "${linhas[@]}"; do
    [[ $l == *unhealthy* || $l == *Restarting* ]] && class=warning
done
tip="Nenhum container rodando"
(( ${#linhas[@]} )) && tip=$(printf '%s\\n' "${linhas[@]}") && tip=${tip%\\n}
tip=${tip//\"/\\\"}
printf '{"text":"󰡨 %s","class":"%s","tooltip":"%s"}\n' "${#linhas[@]}" "$class" "$tip"
