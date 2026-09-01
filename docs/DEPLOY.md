# 部署指南

本文以 Ubuntu/Debian 为例，把一台新服务器初始化为 HBLGLZH 多项目 Web 平台。

## 1. 安装基础软件

```bash
sudo apt update
sudo apt install -y nginx git rsync curl ca-certificates
```

Node.js 只用于构建前端或运行必要的 Node 服务。生产静态站不要运行 `npm run dev`。

推荐使用当前 LTS Node.js，并通过 nvm 或发行版可靠来源安装。

## 2. 初始化平台目录

```bash
sudo mkdir -p /srv/hblglzh
sudo chown "$USER":"$USER" /srv/hblglzh
cd /srv/hblglzh
git clone <platform repo> platform
cd platform
sudo ./scripts/init-server.sh
```

结果：

```text
/srv/hblglzh/platform
/srv/hblglzh/projects
/srv/hblglzh/www
/srv/hblglzh/data
/srv/hblglzh/secrets
/srv/hblglzh/runtime
/srv/hblglzh/backups
/srv/hblglzh/archive
```

## 3. DNS

推荐：

```text
A  @  <服务器 IP>
A  *  <服务器 IP>
```

主域名用于协会官网，通配符记录用于未来学生项目子域名。

## 4. 部署协会官网

```bash
cd /srv/hblglzh/projects
git clone <official repo> official
cd official
npm ci
ASSOCIATION_CONTENT_DIR=/srv/hblglzh/data/official npm run build
```

将官网和 home 的构建产物分别同步到：

```text
/srv/hblglzh/www/official
/srv/hblglzh/www/home
```

如果 official 仓库已经有部署脚本，优先使用其脚本。

## 5. 安装主域名 Nginx 配置

```bash
sudo cp /srv/hblglzh/platform/nginx/hblglzh.cc.conf /etc/nginx/sites-available/hblglzh.cc
sudo ln -sf /etc/nginx/sites-available/hblglzh.cc /etc/nginx/sites-enabled/hblglzh.cc
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

测试：

```bash
curl -I -H 'Host: hblglzh.cc' http://127.0.0.1/
curl -I -H 'Host: hblglzh.cc' http://127.0.0.1/home/
```

## 6. 新增静态项目

```bash
cd /srv/hblglzh/projects
git clone <repo> robot

cd /srv/hblglzh/platform
sudo ./scripts/register-project.sh static robot robot.hblglzh.cc

cd /srv/hblglzh/projects/robot
npm ci
npm run build
sudo /srv/hblglzh/platform/scripts/deploy-static.sh robot dist
```

确认 Nginx：

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 7. 新增动态项目

示例内部端口 `11001`：

```bash
cd /srv/hblglzh/platform
sudo ./scripts/register-project.sh service attendance attendance.hblglzh.cc 11001
```

上传/clone 代码并构建后：

```bash
sudo ./scripts/deploy-service.sh \
  attendance \
  11001 \
  '/usr/bin/node /srv/hblglzh/projects/attendance/dist/server.js' \
  256M \
  50%
```

应用自身必须监听 `127.0.0.1:11001`。

查看：

```bash
sudo systemctl status hblglzh-attendance
sudo journalctl -u hblglzh-attendance -f
```

## 8. HTTPS

可以为少量项目逐个签发证书；项目数量多时建议通配符证书 `*.hblglzh.cc`。

通配符证书通常需要 DNS-01 验证。优先选择支持 DNS API 的域名服务商并配置自动续期。

无论采用哪种方式，HTTPS 仍由 Nginx 统一终止，后端只使用 localhost 内部端口。

## 9. 防火墙

公网只需要：

```text
22/tcp   SSH（最好限制来源 IP 或加强认证）
80/tcp   HTTP
443/tcp  HTTPS
```

不要为 11001、11002 等项目内部端口开放防火墙。

## 10. Swap

2G 内存建议配置 2G swap 作为 OOM 缓冲：

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

加入 `/etc/fstab`：

```text
/swapfile none swap sw 0 0
```

检查：

```bash
free -h
swapon --show
```

## 11. 日常状态

```bash
sudo /srv/hblglzh/platform/scripts/status.sh
```

## 12. 备份

```bash
sudo /srv/hblglzh/platform/scripts/backup.sh
```

默认备份 `data/`，保留 14 天。

如确实需要把 secrets 一并备份：

```bash
sudo BACKUP_SECRETS=1 /srv/hblglzh/platform/scripts/backup.sh
```

包含密钥的备份必须安全保存。
