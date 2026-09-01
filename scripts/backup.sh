#!/usr/bin/env bash
set -Eeuo pipefail

[[ ${EUID} -eq 0 ]] || { echo "请使用 sudo 运行。" >&2; exit 1; }

ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
BACKUP_SECRETS="${BACKUP_SECRETS:-0}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/hblglzh-data-$STAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

items=(data)
if [[ "$BACKUP_SECRETS" == "1" ]]; then
  items+=(secrets)
  echo "警告：本次备份包含 secrets，请确保备份位置安全。"
fi

for item in "${items[@]}"; do
  [[ -e "$ROOT_DIR/$item" ]] || { echo "缺少 $ROOT_DIR/$item" >&2; exit 1; }
done

tar -C "$ROOT_DIR" -czf "$ARCHIVE" "${items[@]}"
chmod 600 "$ARCHIVE"

find "$BACKUP_DIR" -maxdepth 1 -type f -name 'hblglzh-data-*.tar.gz' -mtime "+$RETENTION_DAYS" -delete

echo "备份完成: $ARCHIVE"
echo "保留策略: $RETENTION_DAYS 天"
echo "建议再将备份同步到服务器之外的位置。"
