# 第 4 步：部署 Halo + MySQL（Docker Compose）

> 前置：第 2 步 Docker 已就绪，第 3 步 `/home/exmaterial/blog` 目录已建。
> 说明：域名尚未注册，本步先用**服务器公网 IP** 测试访问。Nginx 反代（第 5 步）、HTTPS（第 6 步）待域名就绪后做。

---

### 4.1 编写 docker-compose.yml

在 `/home/exmaterial/blog` 下创建 `docker-compose.yml`：

```yaml
version: "3.8"

services:
  halo:
    image: halohub/halo:2.20
    container_name: halo
    restart: on-failure:3
    depends_on:
      halodb:
        condition: service_healthy
    ports:
      - "8090:8090"
    volumes:
      - ./halo:/root/.halo2
    command:
      - --spring.r2dbc.url=r2dbc:pool:mysql://halodb:3306/halo
      - --spring.r2dbc.username=halo
      - --spring.r2dbc.password=你的数据库密码
      - --spring.sql.init.platform=mysql
      - --halo.external-url=http://你的公网IP:8090
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

networks:
  halo:
    driver: bridge
```

**替换说明（务必改）：**
- `你的数据库密码`：两处都要改成**同一个强密码**（root、halo 用户共用）
- `你的公网IP`：改成服务器公网 IP
- `2.20`：可改为 Halo 当前最新稳定版（去 [Halo 官网](https://halo.run) 查）

### 4.2 放行 8090 端口

> ⚠️ 腾讯云有**两层**防火墙：① 系统 UFW；② 腾讯云**安全组**。两层都要放通，否则外部访问不通。

系统层：
```bash
sudo ufw allow 8090/tcp
```

腾讯云控制台 → 该实例 → **安全组** → 入站规则 → 添加：协议端口 `TCP:8090`，来源 `0.0.0.0/0`。

> 此 8090 为临时测试端口，第 5 步 Nginx 上线后建议关闭。

如果非云服务器，为轻量应用服务器的话，参考如下

**腾讯云控制台 → 轻量应用服务器 → 选择你的实例 → 防火墙** 

### 4.3 启动

```bash
cd /home/exmaterial/blog
docker compose up -d        # 后台启动
docker compose ps           # 查看容器状态（STATUS 应为 healthy/running）
docker compose logs -f halo # 看启动日志，Ctrl+C 退出
```

### 4.4 验证访问

浏览器打开 `http://你的公网IP:8090`，首次进入初始化页面（创建管理员账号、站点标题等）。

### 4.5 常见排错

- **容器起不来**：`docker compose logs halodb` / `docker compose logs halo` 看错误
- **Halo 连不上 MySQL**：确认三个密码一致、`halodb` 健康（等十几秒）
- **端口不通**：检查 UFW 是否放行 8090，以及**腾讯云安全组**是否放通 8090
- **初始化页面打不开**：确认 `halo` 容器 healthy（`docker compose ps`）

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 4.1 编写 compose | | |
| 4.2 放行 8090（UFW + 安全组） | | |
| 4.3 启动 | | |
| 4.4 浏览器初始化 | | |
| 4.5 排错 | | |
