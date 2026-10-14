# 第 6 步：Let's Encrypt HTTPS 证书自动化

> ⚠️ **前置硬条件（大陆节点）**：① 域名已注册；② DNS 已解析到本机公网 IP；③ **ICP 备案已通过**。三者缺一不可——未备案时腾讯云会拦截 80/443 的域名访问。备案通过前请先停留在第 5 步（IP 访问）。
> 本步用 Let's Encrypt 免费证书 + certbot，自动申请、自动续期。

---

### 6.1 安装 certbot（装在宿主机，不是容器）

```bash
sudo apt update
sudo apt install -y certbot
```

### 6.2 修改 Nginx 配置支持 HTTPS

编辑 `nginx/conf.d/blog.conf`，把 `server_name _` 改成你的域名，并新增 443 监听与跳转：

```nginx
server {
    listen 80;
    server_name exmaterial.cn www.exmaterial.cn;

    # 把 HTTP 全部跳转到 HTTPS
    location / {
        return 301 https://$host$request_uri;
    }

    # ACME 挑战（certbot 验证用，必须保留）
    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }
}

server {
    listen 443 ssl;
    server_name exmaterial.cn www.exmaterial.cn;

    ssl_certificate     /etc/letsencrypt/live/exmaterial.cn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/exmaterial.cn/privkey.pem;

    location / {
        proxy_pass http://halo:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

> 证书路径在宿主机 `/etc/letsencrypt/...`，需要让 nginx 容器能读到。

### 6.3 让 nginx 容器挂载宿主机证书

编辑 `docker-compose.yml`，给 nginx 服务增加一行 volume（在原有 volumes 下追加）：

```yaml
  nginx:
    # ...
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/acme:/var/www/acme:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro      # 新增：挂载证书
```

同时把 halo 的 `external-url` 改为 `https://yourdomain.com`（command 最后一行），让 Halo 生成正确的链接。

### 6.4 申请证书（webroot 方式）

```bash
sudo certbot certonly --webroot \
  -w /home/exmaterial/blog/nginx/acme \
  -d exmaterial.cn -d www.exmaterial.cn \
  --agree-tos -m 3071969304@qq.com
```
成功后证书在 `/etc/letsencrypt/live/yourdomain.com/`。

### 6.5 重启并加载配置

```bash
cd /home/exmaterial/blog
docker compose up -d        # 重新创建 nginx 以挂载证书
docker compose exec nginx nginx -s reload
```

### 6.6 自动续期

certbot 安装后会自带 systemd timer（`certbot renew`），但续期后需要让 nginx 重新加载。加一个 deploy hook：

```bash
sudo certbot renew --dry-run    # 先测试续期流程是否正常
```
续期后 reload 可用 certbot 的 renew-hook：创建 `/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh`：
```bash
#!/bin/bash
docker compose -f /home/exmaterial/blog/docker-compose.yml exec -T nginx nginx -s reload
```
```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

### 6.7 验证

浏览器打开 `https://yourdomain.com`，地址栏应出现锁标；`http://` 会自动跳 `https://`。

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 6.1 安装 certbot | | |
| 6.2 改 nginx 配置 | | |
| 6.3 挂载证书 | | |
| 6.4 申请证书 | | |
| 6.5 重启加载 | | |
| 6.6 自动续期 | | |
| 6.7 验证 HTTPS | | |
