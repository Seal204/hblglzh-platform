#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
用法：
  sudo ./scripts/register-project.sh static  <slug> <domain>
  sudo ./scripts/register-project.sh service <slug> <domain> <port>

示例：
  sudo ./scripts/register-project.sh static robot robot.hblglzh.cc
  sudo ./scripts/register-project.sh service attendance attendance.hblglzh.cc 11001

该脚本会：
  - 创建标准目录
  - 生成并启用 Nginx HTTP 配置
  - 生成 projects.yaml 登记片段到 .generated/
  - service 类型额外创建 data/runtime 目录和 env 示例

不会：
  - clone 项目代码
  - 自动申请 HTTPS 证书
  - 自动编辑 projects.yaml
USAGE
}

[[ $# -ge 3 ]] || { usage; exit 1; }
[[ ${EUID} -eq 0 ]] || { echo "请使用 sudo 运行。" >&2; exit 1; }

TYPE="$1"
PROJECT="$2"
DOMAIN="$3"
PORT="${4:-}"
ROOT_DIR="${HBLGLZH_ROOT:-/srv/hblglzh}"
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN_DIR="$PLATFORM_DIR/.generated"
NGINX_AVAILABLE="${NGINX_AVAILABLE:-/etc/nginx/sites-available}"
NGINX_ENABLED="${NGINX_ENABLED:-/etc/nginx/sites-enabled}"
OWNER="${HBLGLZH_OWNER:-${SUDO_USER:-root}}"
GROUP="${HBLGLZH_GROUP:-$(id -gn "$OWNER" 2>/dev/null || echo "$OWNER")}" 

[[ "$PROJECT" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || {
  echo "slug 只能使用小写字母、数字和连字符，例如 robot-control。" >&2
  exit 1
}

[[ "$DOMAIN" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]] || {
  echo "域名格式不正确: $DOMAIN" >&2
  exit 1
}

case "$TYPE" in
  static) TEMPLATE="$PLATFORM_DIR/nginx/templates/static.conf.template" ;;
  service)
    TEMPLATE="$PLATFORM_DIR/nginx/templates/proxy.conf.template"
    [[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1024 && PORT <= 65535 )) || {
      echo "service 类型需要 1024~65535 的内部端口。" >&2
      exit 1
    }
    ;;
  *) usage; exit 1 ;;
esac

mkdir -p "$ROOT_DIR/projects/$PROJECT" "$GEN_DIR" "$NGINX_AVAILABLE" "$NGINX_ENABLED"
chown -R "$OWNER:$GROUP" "$ROOT_DIR/projects/$PROJECT"

if [[ "$TYPE" == "static" ]]; then
  mkdir -p "$ROOT_DIR/www/$PROJECT"
  chown -R "$OWNER:$GROUP" "$ROOT_DIR/www/$PROJECT"
else
  mkdir -p "$ROOT_DIR/data/$PROJECT" "$ROOT_DIR/runtime/$PROJECT" "$ROOT_DIR/secrets"
  chown -R "$OWNER:$GROUP" "$ROOT_DIR/data/$PROJECT" "$ROOT_DIR/runtime/$PROJECT"
  chmod 700 "$ROOT_DIR/secrets"

  ENV_FILE="$ROOT_DIR/secrets/$PROJECT.env"
  if [[ ! -e "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" <<ENV
NODE_ENV=production
HOST=127.0.0.1
PORT=$PORT
ENV
    chmod 600 "$ENV_FILE"
    chown "$OWNER:$GROUP" "$ENV_FILE"
  fi
fi

NGINX_FILE="$NGINX_AVAILABLE/hblglzh-$PROJECT.conf"
sed \
  -e "s/{{PROJECT}}/$PROJECT/g" \
  -e "s/{{DOMAIN}}/$DOMAIN/g" \
  -e "s/{{PORT}}/$PORT/g" \
  "$TEMPLATE" > "$NGINX_FILE"
ln -sf "$NGINX_FILE" "$NGINX_ENABLED/hblglzh-$PROJECT.conf"

if command -v nginx >/dev/null 2>&1; then
  nginx -t
  systemctl reload nginx 2>/dev/null || true
fi

SNIPPET="$GEN_DIR/$PROJECT.projects.yaml"
if [[ "$TYPE" == "static" ]]; then
  cat > "$SNIPPET" <<YAML
  $PROJECT:
    name: "待填写"
    type: static
    domain: $DOMAIN
    repository: "REPLACE_WITH_REPOSITORY"
    source: $ROOT_DIR/projects/$PROJECT
    output: $ROOT_DIR/www/$PROJECT
    status: development
    owner: "待填写"
YAML
else
  cat > "$SNIPPET" <<YAML
  $PROJECT:
    name: "待填写"
    type: service
    domain: $DOMAIN
    repository: "REPLACE_WITH_REPOSITORY"
    source: $ROOT_DIR/projects/$PROJECT
    data: $ROOT_DIR/data/$PROJECT
    secrets: $ROOT_DIR/secrets/$PROJECT.env
    port: $PORT
    memory: 256M
    status: development
    owner: "待填写"
YAML
fi

cat <<MSG
项目基础结构已创建：$PROJECT
类型：$TYPE
域名：$DOMAIN
Nginx：$NGINX_FILE
项目目录：$ROOT_DIR/projects/$PROJECT
登记片段：$SNIPPET

下一步：
  1. 将项目 clone/上传到 $ROOT_DIR/projects/$PROJECT
  2. 把 $SNIPPET 内容人工加入 projects.yaml
MSG

if [[ "$TYPE" == "static" ]]; then
  echo "  3. npm run build 后执行: sudo $PLATFORM_DIR/scripts/deploy-static.sh $PROJECT dist"
else
  echo "  3. 构建后执行 deploy-service.sh 安装 systemd 服务"
  echo "  4. 确认应用监听 127.0.0.1:$PORT"
fi
