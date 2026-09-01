#!/usr/bin/env bash
set -Eeuo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

echo "[1/4] 检查 Shell 脚本语法"
while IFS= read -r -d '' file; do
  if ! bash -n "$file"; then
    FAILED=1
  fi
done < <(find "$PLATFORM_DIR/scripts" -type f -name '*.sh' -print0)

echo "[2/4] 检查关键文件"
for file in README.md projects.yaml nginx/hblglzh.cc.conf nginx/templates/static.conf.template nginx/templates/proxy.conf.template systemd/webapp.service.template; do
  if [[ ! -s "$PLATFORM_DIR/$file" ]]; then
    echo "缺少或为空: $file" >&2
    FAILED=1
  fi
done

echo "[3/4] 检查模板占位符"
grep -q '{{PROJECT}}' "$PLATFORM_DIR/nginx/templates/static.conf.template" || FAILED=1
grep -q '{{DOMAIN}}' "$PLATFORM_DIR/nginx/templates/static.conf.template" || FAILED=1
grep -q '{{PORT}}' "$PLATFORM_DIR/nginx/templates/proxy.conf.template" || FAILED=1
grep -q '{{EXEC_START}}' "$PLATFORM_DIR/systemd/webapp.service.template" || FAILED=1

echo "[4/4] 可选 Nginx 当前系统配置检查"
if command -v nginx >/dev/null 2>&1; then
  if [[ ${EUID} -eq 0 ]]; then
    nginx -t || FAILED=1
  else
    echo "跳过 nginx -t（需要 root 才能可靠读取全部配置）"
  fi
else
  echo "当前环境未安装 nginx，跳过。"
fi

if (( FAILED )); then
  echo "检查失败。" >&2
  exit 1
fi

echo "检查通过。"
