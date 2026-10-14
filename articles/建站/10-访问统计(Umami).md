# 第 10 步：自建访问统计 Umami（接入现有 Docker 栈）

> 前置（硬条件）：**第 6 步必须已完成**——域名已注册、DNS 已解析、ICP 备案通过、HTTPS 已配好。原因：① Umami 后台走子域名 `stats.yourdomain.com`（需 DNS + 证书）；② 注入 Halo 的追踪脚本是 `https://...`，博客已是 HTTPS，混用 http 会被浏览器拦截。
> 思路：不新增数据库容器，**复用现有 MySQL（halodb）**，新建一个 `umami` 库和用户；Umami 作为第 4 个 compose 服务加入栈，Nginx 反代一个 stats 子域名。正好练「给已有栈加服务 + 反代 + 复用数据库」。
> 资源：Umami 很轻，2 核 4G 上和 Halo/MySQL/Nginx 共存无压力。

---

## 10.1 在现有 MySQL 里建 umami 库和用户

```bash
cd /home/exmaterial/blog
# 建库（utf8mb4）
docker compose exec -T halodb mysql -u root -p"你的数据库密码" \
  -e "CREATE DATABASE umami DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
# 建用户并授权
docker compose exec -T halodb mysql -u root -p"你的数据库密码" \
  -e "CREATE USER 'umami'@'%' IDENTIFIED BY 'umami_pass'; GRANT ALL PRIVILEGES ON umami.* TO 'umami'@'%'; FLUSH PRIVILEGES;"
```
> 把 `umami_pass` 换成强密码，后面 compose 里要用同一个。

## 10.2 给 compose 增加 umami 服务

编辑 `docker-compose.yml`，在 `services:` 下追加（**复用 halodb 这个 MySQL**，不另起库）：

```yaml
  umami:
    image: ghcr.io/umami-software/umami:mysql-v2.15   # mysql- 前缀=MySQL 构建版；版本号去 Umami 官网核对最新稳定版
    container_name: umami
    restart: unless-stopped
    depends_on:
      - halodb
    environment:
      DATABASE_TYPE: mysql
      MYSQL_HOST: halodb
      MYSQL_PORT: "3306"
      MYSQL_DB: umami
      MYSQL_USER: umami
      MYSQL_PASSWORD: umami_pass      # 与 10.1 建用户时一致
      APP_SECRET: replace_with_openssl_hex_32   # 见下方生成命令
    ports:
      - "3002:3000"
    networks:
      - halo
```
生成 `APP_SECRET`：
```bash
openssl rand -hex 32
```
把输出填进 `APP_SECRET`。

## 10.3 DNS 增加 stats 子域名

腾讯云 DNSPod → 你的域名 → 添加记录：`stats` 主机记录，A 类型，值 = 服务器公网 IP（和 @/www 一样）。

## 10.4 Nginx 反代 stats 子域名

在 `nginx/conf.d/` 下新建 `stats.conf`：

```nginx
server {
    listen 443 ssl;
    server_name stats.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://umami:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
> 证书复用主域名的。若证书不含 `stats` 这个 SAN，需回到第 6.4 步重新申请时把 `-d stats.yourdomain.com` 也加进去。

## 10.5 重启并加载

```bash
cd /home/exmaterial/blog
docker compose up -d
docker compose exec nginx nginx -s reload
docker compose ps      # 应看到 umami 状态 healthy/running
```

## 10.6 初始化 Umami + 拿到 website-id

1. 浏览器开 `https://stats.yourdomain.com`
2. 默认账号 **admin / umami** —— **第一时间改密码**（Settings → 修改密码）
3. 左侧 **Settings → Websites → Add website**：Name 填博客名，Domain 填 `yourdomain.com`，保存
4. 列表里点进去看 **Tracking Code**，里面 `data-website-id="xxxx"` 的 `xxxx` 就是网站 ID

## 10.7 把追踪脚本注入 Halo

Halo 后台 → **设置 → 系统 → 代码注入 → 底部** 粘贴（把 id 换成 10.6 拿到的）：

```html
<script async src="https://stats.yourdomain.com/script.js" data-website-id="xxxx"></script>
```

## 10.8 验证

- 访问博客首页几次，过 1–2 分钟到 Umami 后台看是否有访客数据
- 浏览器控制台（F12）Network 里能看到 `script.js` 加载和上报请求 `api/send`

## 10.9 安全加固（建议）

- Umami 后台只你自己看：在 `stats.conf` 的 `location /` 里加 `allow 你的IP; deny all;` 限制来源 IP
- 备份扩展：第 8 步的 mysqldump 当前只备 `halo` 库。Umami 数据在 `umami` 库，若要一起备，把备份命令的库名改成 `halo umami`，或单独加一条

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 10.1 建 umami 库/用户 | | |
| 10.2 加 umami 服务 | | |
| 10.3 DNS stats 子域名 | | |
| 10.4 Nginx 反代 | | |
| 10.5 重启加载 | | |
| 10.6 初始化 + 拿 website-id | | |
| 10.7 注入 Halo | | |
| 10.8 验证 | | |
| 10.9 安全加固 | | |
