# 服务器恢复与换机指南

目标：即使原服务器损坏，也能通过 Git 仓库 + 数据备份重建环境。

## 必须保留的外部资产

Git 能恢复：

- `hblglzh-platform`
- 协会官网源码仓库
- 各学生项目源码仓库

Git 不能恢复：

- `/srv/hblglzh/data`
- `/srv/hblglzh/secrets`
- DNS 管理账号/配置
- TLS 相关账号或 DNS API 凭据

因此至少要有一份服务器外备份。

## 恢复顺序

1. 准备新的 Linux 服务器。
2. 安装 Nginx、Git、rsync、Node.js（按项目需求）。
3. clone `hblglzh-platform` 到 `/srv/hblglzh/platform`。
4. 执行 `sudo ./scripts/init-server.sh`。
5. 恢复 `/srv/hblglzh/data`。
6. 安全恢复 `/srv/hblglzh/secrets`。
7. 根据 `projects.yaml` clone 所有 online 项目。
8. 构建并发布静态项目。
9. 根据项目登记重新安装动态项目 systemd 服务。
10. 恢复 Nginx 配置。
11. 恢复/重新签发 TLS 证书。
12. 修改 DNS A / `*` 记录到新服务器 IP。
13. 执行 `scripts/status.sh` 检查。

## 为什么 platform 仓库很重要

`projects.yaml` 应当成为灾难恢复时的项目索引。每次项目上线、域名变化、端口变化、负责人变化都要及时更新并提交。

## 恢复验收

至少检查：

```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl list-units 'hblglzh-*.service' --all
ss -lntp
free -h
df -h
```

逐个访问 `projects.yaml` 中状态为 online 的域名。
