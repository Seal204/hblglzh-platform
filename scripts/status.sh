#!/usr/bin/env bash
set -u

printf '\n===== HBLGLZH Server Status =====\n'
date

printf '\n--- Uptime ---\n'
uptime || true

printf '\n--- Memory ---\n'
free -h || true

printf '\n--- Disk ---\n'
df -h / /srv 2>/dev/null || df -h / || true

printf '\n--- Swap ---\n'
swapon --show 2>/dev/null || true

printf '\n--- Nginx ---\n'
if command -v nginx >/dev/null 2>&1; then
  nginx -t 2>&1 || true
  systemctl --no-pager --full status nginx 2>/dev/null | sed -n '1,8p' || true
else
  echo "nginx 未安装"
fi

printf '\n--- HBLGLZH Services ---\n'
systemctl list-units 'hblglzh-*.service' --all --no-pager 2>/dev/null || true

printf '\n--- Listening TCP Ports ---\n'
ss -lntp 2>/dev/null || true

printf '\n--- Largest Processes by RAM ---\n'
ps -eo pid,user,%cpu,%mem,rss,comm --sort=-rss 2>/dev/null | head -n 12 || true

printf '\n=================================\n'
