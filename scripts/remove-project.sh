#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "用法: sudo $0 <project>" >&2
  exit 1
fi
[[ ${EUID} -eq 0 ]] || { echo "请使用 sudo 运行。" >&2; exit 1; }

PROJECT="$1"
ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
SITE_AVAILABLE="/etc/nginx/sites-available/hblglzh-$PROJECT.conf"
SITE_ENABLED="/etc/nginx/sites-enabled/hblglzh-$PROJECT.conf"
UNIT="hblglzh-$PROJECT.service"

# 停止动态服务（如果存在）
if systemctl list-unit-files "$UNIT" --no-legend 2>/dev/null | grep -q "$UNIT"; then
  systemctl disable --now "$UNIT" || true
  rm -f "/etc/systemd/system/$UNIT"
  systemctl daemon-reload
fi

rm -f "$SITE_ENABLED" "$SITE_AVAILABLE"
if command -v nginx >/dev/null 2>&1; then
  nginx -t
  systemctl reload nginx 2>/dev/null || true
fi

cat <<MSG
项目 $PROJECT 已从 Nginx/systemd 下线。

为防误删，以下内容未删除：
  $ROOT_DIR/projects/$PROJECT
  $ROOT_DIR/www/$PROJECT
  $ROOT_DIR/data/$PROJECT
  $ROOT_DIR/secrets/$PROJECT.env

确认备份后再人工归档/删除，并更新 projects.yaml。
MSG
