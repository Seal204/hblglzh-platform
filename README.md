# HBLGLZH Server Platform

淮北理工学院卓越工程创新协会 Web 项目服务器管理仓库。

本仓库**只管理服务器基础设施、部署规范和项目登记信息**，不存放具体学生项目源码，也不存放新闻、数据库、上传文件、密钥等运行数据。

## 目标

在一台 2 vCPU / 2 GB RAM 的 Linux 服务器和一个域名 `hblglzh.cc` 上，清晰、低成本地托管多个 Web 项目。

设计原则：

- Nginx 是唯一公网 Web 入口，只开放 80/443。
- 静态项目优先：React/Vue/Vite/Astro 构建后由 Nginx 直接提供。
- 动态项目尽量轻量：Node/Python/Go 等由 systemd 管理，仅监听 `127.0.0.1`。
- Docker 只用于确实需要隔离复杂依赖的项目，不作为默认方案。
- 一个业务项目一个独立 Git 仓库；不要把整台服务器做成一个大仓库。
- 代码、构建产物、持久化数据、密钥、备份严格分离。
- 协会新闻、成果、图片等真实内容不进入 Git。
- 所有线上项目必须登记在 `projects.yaml`。
- 历史/实验项目及时归档或按需启动，避免 2G 内存被长期占用。

## 推荐服务器目录

```text
/srv/hblglzh/
├── platform/                 # 本仓库：服务器管理框架（Git）
├── projects/                 # 各学生项目源码（每个目录独立 Git）
│   ├── official/
│   ├── robot/
│   └── attendance/
├── www/                      # 静态构建产物，不进 Git
│   ├── official/
│   ├── home/
│   └── robot/
├── data/                     # 持久化数据，不进 Git
│   ├── official/
│   └── attendance/
├── secrets/                  # .env/API Key/密码，不进 Git
├── runtime/                  # PID/socket/临时运行文件，不进 Git
├── backups/                  # 数据备份，不进 Git
└── archive/                  # 已下线项目/归档源码
```

## Git 仓库建议

```text
hblglzh-platform        # 本仓库
hblglzh-official        # 协会官网 + /home
hblglzh-robot           # 学生项目
hblglzh-attendance      # 学生项目
hblglzh-competition     # 学生项目
...
```

原则是：**一个产品/系统一个 Repo，而不是一台服务器一个 Repo。**

不推荐把子项目作为 Git Submodule 默认方案。对学生组织而言，独立仓库 + `projects.yaml` 登记更容易交接。

## 当前域名规划

```text
https://hblglzh.cc/             协会官网
https://hblglzh.cc/home/        项目导航
https://robot.hblglzh.cc/       示例学生项目
https://attendance.hblglzh.cc/  示例动态项目
```

DNS 建议：

```text
A    @    <服务器公网 IP>
A    *    <服务器公网 IP>
```

`*` 是通配符子域名。以后新增 `xxx.hblglzh.cc` 不需要逐条增加 DNS A 记录。

## 目录内容

```text
.
├── README.md
├── projects.yaml
├── nginx/
│   ├── hblglzh.cc.conf
│   └── templates/
│       ├── static.conf.template
│       └── proxy.conf.template
├── systemd/
│   └── webapp.service.template
├── scripts/
│   ├── init-server.sh
│   ├── register-project.sh
│   ├── deploy-static.sh
│   ├── deploy-service.sh
│   ├── remove-project.sh
│   ├── status.sh
│   ├── backup.sh
│   └── check-config.sh
├── examples/
│   └── service.env.example
└── docs/
    ├── DEPLOY.md
    ├── PROJECT_GUIDE.md
    ├── RESOURCE_POLICY.md
    └── SERVER_RECOVERY.md
```

## 首次初始化

在服务器上 clone：

```bash
sudo mkdir -p /srv/hblglzh
sudo chown "$USER":"$USER" /srv/hblglzh
cd /srv/hblglzh
git clone <你的仓库地址> platform
```

初始化目录：

```bash
cd /srv/hblglzh/platform
sudo ./scripts/init-server.sh
```

安装协会官网基础 Nginx 配置：

```bash
sudo cp nginx/hblglzh.cc.conf /etc/nginx/sites-available/hblglzh.cc
sudo ln -sf /etc/nginx/sites-available/hblglzh.cc /etc/nginx/sites-enabled/hblglzh.cc
sudo nginx -t
sudo systemctl reload nginx
```

完整步骤见 `docs/DEPLOY.md`。

## 新增静态项目

例如项目：

```text
slug: robot
domain: robot.hblglzh.cc
```

先 clone 项目：

```bash
cd /srv/hblglzh/projects
git clone <robot 仓库地址> robot
```

登记/生成 Nginx 配置：

```bash
cd /srv/hblglzh/platform
sudo ./scripts/register-project.sh static robot robot.hblglzh.cc
```

构建并发布：

```bash
cd /srv/hblglzh/projects/robot
npm ci
npm run build

sudo /srv/hblglzh/platform/scripts/deploy-static.sh robot dist
```

然后把项目补充登记到 `projects.yaml` 并提交 platform 仓库。

## 新增动态项目

例如：

```text
slug: attendance
domain: attendance.hblglzh.cc
internal port: 11001
```

创建：

```bash
sudo ./scripts/register-project.sh service attendance attendance.hblglzh.cc 11001
```

安装 systemd：

```bash
sudo ./scripts/deploy-service.sh \
  attendance \
  11001 \
  '/usr/bin/node /srv/hblglzh/projects/attendance/dist/server.js'
```

动态应用自身必须监听：

```text
127.0.0.1:11001
```

不要监听公网 `0.0.0.0:11001`。

## 2C2G 资源规则

- 静态站：优先，数量基本不受常驻进程限制。
- 普通动态项目：建议每个 `MemoryMax=256M` 左右。
- Java/AI/大型数据库：非必要不要常驻。
- 能用 SQLite 的低并发项目优先 SQLite。
- 如需中心数据库，尽量共享一个 PostgreSQL/MySQL 实例，而不是每项目一套。
- 建议配置 2G swap 防止瞬时 OOM，但不能把 swap 当内存使用。
- 建议日常内存占用控制在约 1.0~1.4G，保留余量。

更多规则见 `docs/RESOURCE_POLICY.md`。

## 日常检查

```bash
sudo ./scripts/status.sh
```

检查脚本及配置文件：

```bash
./scripts/check-config.sh
```

## 数据备份

```bash
sudo ./scripts/backup.sh
```

默认备份 `/srv/hblglzh/data`，保留 14 天。

注意：**不进 Git 不等于不备份。** 新闻、照片、SQLite 数据库、上传文件通常比代码更重要，最好再同步一份到另一台设备或对象存储。

## 严禁

- 不要提交 `/srv/hblglzh/data` 到 Git。
- 不要提交 `.env`、API Key、数据库密码、证书私钥。
- 不要在生产环境运行 `npm run dev`。
- 不要让 Node/Python/Java 应用直接暴露公网端口。
- 不要直接编辑 `/srv/hblglzh/www` 里的构建产物。
- 不要让单个项目无限制占用 CPU/内存。
- 不要删除项目数据目录来“卸载”项目；先归档和备份。

## 交接建议

每届服务器管理员至少需要掌握：

1. `projects.yaml` 中每个项目的用途、负责人、域名、仓库和运行类型。
2. Nginx 配置位置。
3. systemd 服务查看/重启方法。
4. `/srv/hblglzh/data` 与 `/srv/hblglzh/secrets` 的备份位置。
5. 域名 DNS 和 TLS 证书的管理账号交接方式。
6. `docs/SERVER_RECOVERY.md` 中的灾难恢复流程。
