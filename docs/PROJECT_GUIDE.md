# 学生项目上线规范

## 1. 项目必须有明确 slug

使用小写英文字母、数字、连字符：

```text
robot-control
attendance
competition-2026
```

不要使用：

```text
项目1
new_project
Test App
```

slug 会用于目录名、systemd 服务名和部分配置文件名。

## 2. 一个独立系统一个 Git 仓库

推荐：

```text
hblglzh-official
hblglzh-robot-control
hblglzh-attendance
```

不要把所有学生项目继续塞到官网 monorepo。

如果前后端本身属于同一产品，可以在该产品自己的仓库内部做 monorepo。

## 3. 项目分类

### static

适用于：

- React/Vite
- Vue/Vite
- Astro 静态输出
- HTML/CSS/JS

生产流程：

```text
源码 -> npm run build -> dist -> /srv/hblglzh/www/<slug> -> Nginx
```

生产环境不运行 Node dev server。

### service

适用于必须常驻的：

- Node API
- Python API
- Go 服务
- 小型 Java 服务

必须：

- 由 systemd 管理。
- 监听 `127.0.0.1:<port>`。
- Nginx 反向代理。
- 设置合理内存限制。
- 持久化数据写入 `/srv/hblglzh/data/<slug>`。
- secret 放 `/srv/hblglzh/secrets/<slug>.env`。

### ondemand

资源较重或仅用于演示的项目。

默认关闭，需要展示时人工启动，用完停止。

### archive

已结束项目。关闭动态进程，保留源码和必要的静态成果/数据备份。

## 4. 域名

项目优先使用：

```text
<slug>.hblglzh.cc
```

例如：

```text
robot.hblglzh.cc
attendance.hblglzh.cc
```

不推荐新项目继续使用 `/app1` `/app2` 这类无语义路径。

## 5. 项目登记

每个线上项目必须加入 `/srv/hblglzh/platform/projects.yaml`，至少填写：

- 名称
- 类型
- 域名
- Git 仓库
- 源码路径
- 负责人
- 状态
- 动态项目端口/内存限制
- 数据目录

`register-project.sh` 会生成一个 YAML 片段，但最终由管理员人工审核后加入 `projects.yaml`。

## 6. 静态项目发布

项目负责人：

```bash
npm ci
npm run build
```

管理员：

```bash
sudo /srv/hblglzh/platform/scripts/deploy-static.sh <slug> dist
```

不要让 Nginx 直接指向源码目录。

## 7. 动态项目端口

建议统一使用一个内部端口区间，例如：

```text
11001-11999
```

每个端口必须登记到 `projects.yaml`，避免冲突。

查看占用：

```bash
ss -lntp
```

## 8. 数据约定

应用不得把重要运行数据只写在项目源码目录。

正确：

```text
/srv/hblglzh/data/attendance/database.sqlite
/srv/hblglzh/data/attendance/uploads/
```

错误：

```text
/srv/hblglzh/projects/attendance/database.sqlite
/srv/hblglzh/projects/attendance/uploads/
```

这样重新 clone/部署项目不会覆盖真实数据。

## 9. Secrets

`.env`、API Key、数据库密码、JWT Secret 不得提交 Git。

服务器统一：

```text
/srv/hblglzh/secrets/<slug>.env
```

权限建议：

```bash
chmod 600 /srv/hblglzh/secrets/<slug>.env
```

## 10. 项目下线

先执行：

```bash
sudo /srv/hblglzh/platform/scripts/remove-project.sh <slug>
```

该脚本只停止服务/移除 Nginx 配置，不删除源码和数据。

之后：

1. 备份数据。
2. 把项目状态改为 archive。
3. 必要时把源码目录移动到 `/srv/hblglzh/archive`。
4. 确认无恢复需求后再删除生产构建产物。
