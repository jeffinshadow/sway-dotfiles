#!/usr/bin/env bash
# backup-drive.sh — backup da giratina no Google Drive (restic + rclone, remote "gdrive").
# Repositório: gdrive:backup-giratina (criptografado pelo restic; a senha fica em
# ~/.config/restic/senha, FORA do git — guarde uma cópia longe da máquina, sem ela o
# backup não abre). Rodado todo dia pelo timer de usuário backup-drive.timer.
#   backup-drive.sh            faz o backup + limpeza (retenção) e, aos domingos, check
#   backup-drive.sh snapshots  lista os backups
#   backup-drive.sh restaurar <snapshot|latest> <destino>   restaura numa pasta
set -euo pipefail
export RESTIC_REPOSITORY="rclone:gdrive:backup-giratina"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/senha"
export RESTIC_CACHE_DIR="$HOME/.cache/restic"
here="$(dirname "$(readlink -f "$0")")"

case "${1:-backup}" in
  snapshots) exec restic snapshots ;;
  restaurar) exec restic restore "${2:?snapshot}" --target "${3:?destino}" ;;
  backup) ;;
  *) echo "uso: $0 [backup|snapshots|restaurar <id> <destino>]" >&2; exit 2 ;;
esac

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }
log "início"
paths=()
while IFS= read -r p; do
  [[ -z "$p" || "$p" == \#* ]] && continue
  p="${p/#\~/$HOME}"; [[ -e "$p" ]] && paths+=("$p")
done < "$here/incluir.txt"

restic backup --one-file-system --exclude-caches \
  --exclude-file "$here/excluir.txt" --tag diario "${paths[@]}"
restic forget --tag diario --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
[[ "$(date +%u)" == 7 ]] && restic check --read-data-subset=5%
log "fim: ok"
