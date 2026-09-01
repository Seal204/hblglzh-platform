#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
用法：
  sudo ./scripts/deploy-service.sh <project> <port> <exec-start> [memory-max=256M] [cpu-quota=50%]

示例：
  sudo ./scripts/deploy-service.sh \
    attendance \
    11001 \
    '/usr/bin/node /srv/hblglzh/projects/attendance/dist/server.js' \
    256M \
    50%

说明：应用必须自己监听 127.0.0.1:<port>。
USAGE
}

[[ $# -ge 3 && $# -le 5 ]] || { usage; exit 1; }
[[ ${EUID} -eq 0 ]] || { echo "请使用 sudo 运行。" >&2; exit 1; }

PROJECT="$1"
PORT="$2"
EXEC_START="$3"
MEMORY_MAX="${4:-256M}"
CPU_QUOTA="${5:-50%}"
ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$PLATFORM_DIR/systemd/webapp.service.template"
RUN_USER="${HBLGLZH_OWNER:-${SUDO_USER:-root}}"
RUN_GROUP="${HBLGLZH_GROUP:-$(id -gn "$RUN_USER" 2>/dev/null || echo "$RUN_USER")}" 
UNIT="/etc/systemd/system/hblglzh-$PROJECT.service"

[[ "$PROJECT" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || { echo "非法 project slug" >&2; exit 1; }
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1024 && PORT <= 65535 )) || { echo "非法端口" >&2; exit 1; }
[[ -d "$ROOT_DIR/projects/$PROJECT" ]] || { echo "项目目录不存在: $ROOT_DIR/projects/$PROJECT" >&2; exit 1; }

mkdir -p "$ROOT_DIR/data/$PROJECT" "$ROOT_DIR/runtime/$PROJECT" "$ROOT_DIR/secrets"
chown -R "$RUN_USER:$RUN_GROUP" "$ROOT_DIR/data/$PROJECT" "$ROOT_DIR/runtime/$PROJECT"
chmod 700 "$ROOT_DIR/secrets"

escape_sed() { printf '%s' "$1" | sed 's/[&|]/\\&/g'; }

sed \
  -e "s|{{PROJECT}}|$(escape_sed "$PROJECT")|g" \
  -e "s|{{RUN_USER}}|$(escape_sed "$RUN_USER")|g" \
  -e "s|{{RUN_GROUP}}|$(escape_sed "$RUN_GROUP")|g" \
  -e "s|{{EXEC_START}}|$(escape_sed "$EXEC_START")|g" \
  -e "s|{{MEMORY_MAX}}|$(escape_sed "$MEMORY_MAX")|g" \
  -e "s|{{CPU_QUOTA}}|$(escape_sed "$CPU_QUOTA")|g" \
  "$TEMPLATE" > "$UNIT"

systemctl daemon-reload
systemctl enable --now "hblglzh-$PROJECT.service"
systemctl --no-pager --full status "hblglzh-$PROJECT.service" || true

cat <<MSG
systemd 服务已安装：hblglzh-$PROJECT.service
内部端口登记值：$PORT

常用命令：
  sudo systemctl restart hblglzh-$PROJECT
  sudo systemctl status hblglzh-$PROJECT
  sudo journalctl -u hblglzh-$PROJECT -f

请确认应用实际监听的是 127.0.0.1:$PORT，而不是 0.0.0.0:$PORT。
MSG
