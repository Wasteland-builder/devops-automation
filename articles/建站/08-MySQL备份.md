# 第 8 步：MySQL 定时备份脚本

> 前置：第 4 步 MySQL 已在 Docker 中运行（容器名 `halodb`，库名 `halo`）。
> 目标：每天定时 `mysqldump` 备份，压缩存档，保留最近 7 天。

---

### 8.1 写备份脚本 `backup.sh`

```bash
mkdir -p /home/exmaterial/blog/backups
cat > /home/exmaterial/blog/backup.sh <<'EOF'
#!/bin/bash
set -e
COMPOSE=/home/exmaterial/blog/docker-compose.yml
BAK_DIR=/home/exmaterial/blog/backups
DB_PASS="你的数据库密码"
DATE=$(date +%F-%H%M)

mkdir -p "$BAK_DIR"
docker compose -f "$COMPOSE" exec -T halodb \
  mysqldump -u root -p"$DB_PASS" halo \
  | gzip > "$BAK_DIR/halo-$DATE.sql.gz"

# 只保留最近 7 天
find "$BAK_DIR" -name '*.sql.gz' -mtime +7 -delete
echo "$(date) backup done: halo-$DATE.sql.gz"
EOF
chmod +x /home/exmaterial/blog/backup.sh
```

> `exec -T` 的 `-T` 关闭伪终端，避免 mysqldump 输出混入告警；管道直接 gzip 落盘，不落中间明文文件。

### 8.2 手动测一次

```bash
/home/exmaterial/blog/backup.sh
ls -lh /home/exmaterial/blog/backups/
```

### 8.3 加入 cron 定时（每天 03:00）

```bash
crontab -e
# 末尾加一行：
0 3 * * * /home/exmaterial/blog/backup.sh >> /home/exmaterial/blog/backups/cron.log 2>&1
```
验证：`crontab -l`

### 8.4 恢复演练（重要，建议至少做一次）

```bash
# 解压后导入
gunzip -c /home/exmaterial/blog/backups/halo-xxxxxxxx.sql.gz \
 | docker compose -f /home/exmaterial/blog/docker-compose.yml exec -T halodb \
   mysql -u root -p"你的数据库密码" halo
```

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 8.1 写脚本 | | |
| 8.2 手动测试 | | |
| 8.3 cron 定时 | | |
| 8.4 恢复演练 | | |
