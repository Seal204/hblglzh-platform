#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
OWNER="${HBLGLZH_OWNER:-${SUDO_USER:-$(id -un)}}"
GROUP="${HBLGLZH_GROUP:-$(id -gn "$OWNER" 2>/dev/null || echo "$OWNER")}" 

if [[ ${EUID} -ne 0 ]]; then
  echo "请使用 sudo 运行: sudo $0" >&2
  exit 1
fi

for dir in projects www data secrets runtime backups archive; do
  mkdir -p "$ROOT_DIR/$dir"
done

chown -R "$OWNER:$GROUP" \
  "$ROOT_DIR/projects" \
  "$ROOT_DIR/www" \
  "$ROOT_DIR/data" \
  "$ROOT_DIR/runtime" \
  "$ROOT_DIR/archive"

chmod 755 "$ROOT_DIR" "$ROOT_DIR/projects" "$ROOT_DIR/www" "$ROOT_DIR/data" "$ROOT_DIR/runtime" "$ROOT_DIR/archive"
chmod 700 "$ROOT_DIR/secrets" "$ROOT_DIR/backups"

mkdir -p "$ROOT_DIR/data/official/media" "$ROOT_DIR/www/official" "$ROOT_DIR/www/home"
chown -R "$OWNER:$GROUP" "$ROOT_DIR/data/official" "$ROOT_DIR/www/official" "$ROOT_DIR/www/home"
chmod -R u+rwX,go+rX "$ROOT_DIR/data/official/media" "$ROOT_DIR/www/official" "$ROOT_DIR/www/home"

cat <<MSG
初始化完成：$ROOT_DIR

目录：
  $ROOT_DIR/projects   项目源码
  $ROOT_DIR/www        静态构建产物
  $ROOT_DIR/data       持久化数据
  $ROOT_DIR/secrets    密钥（700）
  $ROOT_DIR/runtime    临时运行数据
  $ROOT_DIR/backups    备份（700）
  $ROOT_DIR/archive    已归档项目

建议下一步：
  1. clone 协会官网到 $ROOT_DIR/projects/official
  2. 构建并发布到 $ROOT_DIR/www/official 和 $ROOT_DIR/www/home
  3. 安装 nginx/hblglzh.cc.conf
MSG
