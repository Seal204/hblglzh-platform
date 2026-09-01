#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "用法: sudo $0 <project> [dist-dir=dist]" >&2
  exit 1
fi
[[ ${EUID} -eq 0 ]] || { echo "请使用 sudo 运行。" >&2; exit 1; }

PROJECT="$1"
DIST_ARG="${2:-dist}"
ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
SOURCE_DIR="$ROOT_DIR/projects/$PROJECT"
TARGET_DIR="$ROOT_DIR/www/$PROJECT"
OWNER="${HBLGLZH_OWNER:-${SUDO_USER:-root}}"
GROUP="${HBLGLZH_GROUP:-$(id -gn "$OWNER" 2>/dev/null || echo "$OWNER")}" 

if [[ "$DIST_ARG" = /* ]]; then
  DIST_DIR="$DIST_ARG"
else
  DIST_DIR="$SOURCE_DIR/$DIST_ARG"
fi

[[ -d "$DIST_DIR" ]] || { echo "构建目录不存在: $DIST_DIR" >&2; exit 1; }
[[ -f "$DIST_DIR/index.html" ]] || echo "警告: $DIST_DIR 中没有 index.html，请确认项目类型。" >&2

mkdir -p "$TARGET_DIR"
rsync -a --delete "$DIST_DIR/" "$TARGET_DIR/"
chown -R "$OWNER:$GROUP" "$TARGET_DIR"
chmod -R u+rwX,go+rX "$TARGET_DIR"

echo "发布完成: $DIST_DIR -> $TARGET_DIR"
