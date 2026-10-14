# 第 5 步：Nginx 反向代理（收口 8090）

> 前置：第 4 步 Halo + MySQL 已跑通，`http://公网IP:8090` 可访问。
> 本步把 Nginx 加进同一份 compose，由它对外提供 80 端口并反代到 Halo，之后**关闭 8090 直连**——更规范，也为第 6 步 HTTPS 铺路。
> 域名还没注册也能做（先用 IP 访问）。

---

### 5.1 更新 docker-compose.yml

用下面完整内容**替换** `/home/exmaterial/blog/docker-compose.yml`（主要变化：halo 不再对外暴露 8090；新增 nginx 服务；去掉显式 `driver: bridge` 规避之前的网桥问题）：

```yaml
services:
  halo:
    image: halohub/halo:2.20
    container_name: halo
    restart: on-failure:3
    depends_on:
      halodb:
        condition: service_healthy
    volumes:
      - ./halo:/root/.halo2
    command:
      - --spring.r2dbc.url=r2dbc:pool:mysql://halodb:3306/halo
      - --spring.r2dbc.username=halo
      - --spring.r2dbc.password=你的数据库密码
      - --spring.sql.init.platform=mysql
      - --halo.external-url=http://你的公网IP
    networks:
      - halo
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8090/actuator/health/readiness"]
      interval: 30s
      timeout: 5s
      retries: 5

  halodb:
    image: mysql:8.0.33
    container_name: halodb
    restart: on-failure:3
    command:
      - --default-authentication-plugin=mysql_native_password
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_general_ci
      - --explicit-defaults-for-timestamp=true
    volumes:
      - ./mysql:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=你的数据库密码
      - MYSQL_DATABASE=halo
      - MYSQL_USER=halo
      - MYSQL_PASSWORD=你的数据库密码
      - TZ=Asia/Shanghai
    networks:
      - halo
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--password=你的数据库密码"]
      interval: 10s
      timeout: 5s
      retries: 10

  nginx:
    image: nginx:1.27
    container_name: nginx
    restart: on-failure:3
    depends_on:
      - halo
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/acme:/var/www/acme:ro
    networks:
      - halo

networks:
  halo:
```

> 同样把 `你的数据库密码` 和 `你的公网IP` 换成实际值；镜像版本按需调整。

### 5.2 建目录

```bash
cd /home/exmaterial/blog
mkdir -p nginx/conf.d nginx/ssl nginx/acme
```

### 5.3 写 Nginx 配置 `nginx/conf.d/blog.conf`

```nginx
server {
    listen 80;
    server_name exmaterial.cn;   # 域名就绪后改成你的域名，如 yourdomain.com

    # ACME 挑战目录（第 6 步申请 HTTPS 证书用，提前建好不影响）
    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }

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

### 5.4 防火墙：关 8090，确认 80 开

```bash
sudo ufw delete allow 8090/tcp   # 系统层关闭 8090
sudo ufw allow 80/tcp            # 确认 80 开放（第1步已开，重复无妨）
sudo ufw status
```
腾讯云**安全组**也把 `TCP:8090` 入站规则删掉，保留 `TCP:80` 和 `TCP:443`。

### 5.5 重启服务

```bash
cd /home/exmaterial/blog
docker compose up -d
docker compose ps
```

### 5.6 验证

浏览器打开 `http://你的公网IP` —— 应直接看到 Halo（经 Nginx 反代），不再需要加 `:8090`。

### 5.7 排错

- 打不开：看 `docker compose logs nginx`；确认 80 在安全组和 UFW 都放行
- 502 Bad Gateway：halo 没起来 / 还没 healthy，`docker compose logs halo` 排查
- 配置改了不生效：`docker compose exec nginx nginx -s reload`

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 5.1 更新 compose | | |
| 5.2 建目录 | | |
| 5.3 写 blog.conf | | |
| 5.4 关 8090 / 开 80 | | |
| 5.5 重启 | | |
| 5.6 验证 | | |
