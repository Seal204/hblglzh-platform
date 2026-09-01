# 2C2G 服务器资源规范

服务器资源有限，因此项目上线首先考虑是否能静态化，而不是默认启动常驻服务。

## 优先级

```text
静态 Nginx > 轻量 service > 按需 service > Docker/重型服务
```

## 静态项目

React/Vue/Astro 等能构建成静态文件时，生产环境只保留构建产物，由 Nginx 提供。

静态项目几乎不增加常驻应用内存。

## 动态项目

普通项目建议：

```text
MemoryMax: 128M ~ 256M
CPUQuota: 25% ~ 50%
```

确有需求再提高。

不要在 2G 服务器上长期运行大量 Node/Python/Java 实例。

## 数据库

低并发、单机型学生项目优先考虑 SQLite。

确实需要数据库服务器时：

- 尽量共享一个 PostgreSQL/MySQL 实例。
- 每个项目使用独立 database/user 权限。
- 不要每个项目各起一套 MySQL/PostgreSQL。
- Redis 只有有明确需求时才部署。

## Java

Spring Boot 等 Java 服务在 2G 环境中需要严格限制堆：

```bash
java -Xms64m -Xmx256m -jar app.jar
```

大型 Java 项目更适合按需运行或迁移到资源更大的服务器。

## Node.js

必要时可额外限制 V8 堆：

```bash
node --max-old-space-size=192 dist/server.js
```

但 systemd 的 `MemoryMax` 仍然是最终资源保护线。

## Docker

Docker 不是禁止使用，但不作为每个项目的默认包装层。

适合 Docker 的情况：

- 特殊系统依赖。
- 难以在宿主机统一管理的环境。
- 必须与宿主隔离的第三方服务。

纯静态项目不要为了“统一”而套 Docker。

## Swap

建议 2G swap 作为瞬时内存不足时的保护。

Swap 很慢，不应该依赖它长期承载工作集。

## 监控

日常：

```bash
free -h
df -h
htop
ss -lntp
sudo /srv/hblglzh/platform/scripts/status.sh
```

建议长期给系统保留几百 MB 内存余量，不要让内存长期贴近 2G 上限。

## 日志

优先使用 systemd journal，并定期检查：

```bash
journalctl --disk-usage
```

不要让应用无上限写日志文件。

## 项目生命周期

- online：长期运行的必要项目。
- ondemand：需要时启动。
- archive：关闭动态服务，仅保留成果与备份。

学生项目结束后要主动归档，不能无限累积常驻进程。
