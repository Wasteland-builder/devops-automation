# 第 9 步：Uptime Kuma 监控告警

> 前置：服务已运行。本步部署 Uptime Kuma，监控博客可用性，并在宕机时告警（邮件 / Telegram / Webhook）。

---

### 9.1 在 compose 中增加 kuma 服务

编辑 `/home/exmaterial/blog/docker-compose.yml`，在 `services:` 下追加：

```yaml
  uptime-kuma:
    image: louislam/uptime-kuma:1.23
    container_name: uptime-kuma
    restart: on-failure:3
    volumes:
      - ./kuma:/app/data
    ports:
      - "3001:3001"
    networks:
      - halo
```
然后：
```bash
cd /home/exmaterial/blog
mkdir -p kuma
docker compose up -d uptime-kuma
```

### 9.2 开放端口

```bash
sudo ufw allow 3001/tcp
```
腾讯云**安全组**入站加 `TCP:3001`。
> 更稳妥：不暴露 3001，而是像博客一样用 Nginx 反代 + HTTPS 访问 Kuma。进阶做法，初版可先直接开 3001。

### 9.3 初始化与添加监控

1. 浏览器打开 `http://你的公网IP:3001`，首次设置管理员账号
2. 左侧 **Add New Monitor**：
   - Monitor Type：`HTTP(s)`
   - URL：`http://你的公网IP`（HTTPS 就绪后改 `https://你的域名`）
   - Interval：60 秒
3. Save

### 9.4 配置告警

左侧 **Notifications** → **Setup Notification** → 选渠道：
- **Email**：填 SMTP（可用腾讯企业邮 / QQ 邮箱授权码）
- **Telegram**：填 Bot Token + Chat ID
- **Webhook**：推到企业微信 / 飞书 / 钉钉

建好后，在 Monitor 的 **Notifications** 标签里勾选该告警，保存。宕机即触发。

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 9.1 加 kuma 服务 | | |
| 9.2 开放 3001 | | |
| 9.3 添加监控 | | |
| 9.4 配置告警 | | |
