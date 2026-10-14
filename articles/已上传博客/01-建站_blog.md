# 写在开头

其实早在22年的时候，当时用hexo及gitee子域名挂载的方式搞了一个静态博客网站，眨眼已经过去四年了，当时的网站现在也没法访问了。突然兴起想重新搞一个博客网站，四年后，技术虽然没什么长进，但也要拥抱AI，这次就用codebuddy IDE搭配DeepSeek网页版答疑，做一个更完善的博客吧。

> 目标：通过搭建个人博客，学习并实践运维核心技能。
> 适用环境：腾讯云 ECS（2 核 4G）+ 自定义域名 + Ubuntu 22.04 LTS。

# 一、技术栈总览

```
浏览器 → Nginx(HTTPS/反向代理) → Halo(Java 应用, 内置 Web 服务) → MySQL 8.0
        以上全部用 Docker Compose 编排
        另跑 Uptime Kuma 做监控
```

| 层       | 选型                                     | 运维练手点                                   |
| -------- | ---------------------------------------- | -------------------------------------------- |
| 操作系统 | Ubuntu 22.04 LTS                         | Linux 管理、systemd、权限、防火墙            |
| 博客应用 | Halo（Java，官方 Docker 镜像，开箱即用） | 容器化部署、应用升级、配置管理               |
| 反向代理 | Nginx（域名访问暂未实现）                | 静态文件、反向代理、HTTPS                    |
| 数据库   | MySQL 8.0                                | 容器化、备份(mysqldump)、迁移、持久化 volume |
| 容器化   | Docker + Docker Compose                  | 多服务编排、可复现部署                       |
| 部署     | Git + GitHub Actions（可选）（暂未实现） | 自动构建、自动部署                           |
| 证书     | Let's Encrypt + certbot（暂未实现）      | HTTPS 自动化续期                             |
| 监控     | Uptime Kuma（暂未实现）                  | 可用性监控、告警                             |

大概花费：腾讯云新用户2核 4G 6M 三年  528 + 域名注册 109 = 637 

# 二、第 1 步：服务器初始化

> 假设镜像为 Ubuntu 22.04 LTS。若选了 CentOS/TencentOS，命令会不同，需先确认。
> 所有命令在服务器上以 demo 用户执行（需管理员权限时加 sudo）。

### 2.1 先确认系统

```bash
cat /etc/os-release | head -n 2
uname -a
```

确认输出为 Ubuntu 22.04。

### 2.2 更新系统（补丁管理）

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.3 创建普通用户（别一直用 root）

```bash
adduser demo         # 按提示设密码、填信息（可一路回车）
usermod -aG sudo demo   # 加入 sudo 组

#注意，新建用户后默认的Shell 为 sh，需要修改为bash，参考如下命令
# 首先查看当前用户的默认shell
getent passwd demo
# 如果输出最后是 /bin/sh 或 /bin/dash，就需要改成 /bin/bash。用 root 权限执行：
sudo usermod -s /bin/bash exmaterial
#复制配置文件到家目录
#Ubuntu 系统在 /etc/skel/ 目录下存放了默认的配置文件模板（如 .bashrc、.profile）。把这些复制到 exmaterial 的家目录，并修改所有权：
sudo cp /etc/skel/.bashrc /etc/skel/.profile /home/demo/
sudo chown demo:demo /home/demo/.bashrc /home/demo/.profile
# 退出当前回话并重新登录
```

### 2.4 配置 SSH 密钥登录（在本地电脑执行）

```bash
# 本地生成密钥（若已有可跳过）
ssh-keygen -t ed25519 -C "demo@blog"

# 本地把公钥拷到服务器（注意，该工具windows没有，所以我们要换一个方案）
ssh-copy-id demo@服务器公网IP

# 在本地 Windows PowerShell 里，查看你的公钥内容
cat ~\.ssh\id_ed25519.pub
# 首次新增
echo "你的完整公钥内容" >> ~/.ssh/authorized_keys
# 追加
echo "你的完整公钥内容" | sudo tee -a /home/demo/.ssh/authorized_keys

# 确保权限和所有者正确
sudo chown -R demo:demo /home/demo/.ssh
sudo chmod 700 /home/demo/.ssh
sudo chmod 600 /home/demo/.ssh/authorized_keys
```

### 2.5 加固 SSH（禁用密码登录）

登录 `demo` 用户后：

```bash
sudo sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

> ⚠️ 改完先别断开当前连接，新开终端测试 `ssh deploy@IP` 能登录再继续，否则可能锁死自己。

### 2.6 配置防火墙 UFW

```bash
sudo apt install ufw -y
sudo ufw default deny incoming   # 默认拒绝入站
sudo ufw default allow outgoing  # 默认允许出站
sudo ufw allow 22/tcp            # SSH
sudo ufw allow 80/tcp            # HTTP
sudo ufw allow 443/tcp           # HTTPS
sudo ufw enable
sudo ufw status
```

### 2.7 安装 fail2ban（防暴力破解）

```bash
sudo apt install fail2ban -y
sudo systemctl enable --now fail2ban
```

### 2.8 基础工具 + 时区

```bash
sudo apt install -y curl wget git vim tmux htop unzip
sudo timedatectl set-timezone Asia/Shanghai
```

# 三、第 2 步：安装 Docker 与 Docker Compose

> 适用 Ubuntu 22.04。在 `demo 用户下执行（管理员命令加 `sudo`）。
> 本步安装容器运行时，后续 Halo / MySQL / Nginx / Uptime Kuma 全部跑在 Docker 里。

---

### 3.1 卸载旧版本（如没有会提示无此包，忽略即可）

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
```

### 3.2 安装依赖与添加 Docker 官方仓库

```bash
# 给你的 Ubuntu 系统添加一个“Docker 官方应用商店”的地址，并装好安全证书，确保从那里下载的软件是正版且安全的
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 3.3 安装 Docker 引擎与 Compose 插件

```bash
# 也许你会好奇为什么不使用 sudo apt insatll docker.io -y 直接安装，巧了，我也是。所以我去查了一下，docker.io 是 Ubuntu 官方仓库维护的老版本，通常滞后官方好几年，且不支持新版 docker compose 的插件化架构。而 docker-ce 是 Docker 公司官方提供的最新生产版本，Bug 修复更快，功能也更多，对你的建站部署更友好。
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3.4 启动并设置开机自启

```bash
sudo systemctl enable --now docker
```

### 3.5 让 deploy 用户免 sudo 使用 docker

```bash
sudo usermod -aG docker $USER
```

> 执行后**必须退出 SSH 重新登录**，`docker` 组权限才会生效。

### 3.6（推荐）配置腾讯云镜像加速

国内拉取 Docker 镜像慢，配置腾讯云加速器提速：

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
EOF
sudo systemctl restart docker
```

### 3.7 验证安装

```bash
docker version
docker compose version
docker run --rm hello-world
```

看到 `Hello from Docker!` 即成功。

# 四、第 3 步：域名解析 + 项目目录结构

> 本步做两件事：把域名指向服务器公网 IP，以及在服务器上规划好后续部署的目录结构。
> 注意：本步不涉及 Docker 部署，但目录结构是后面所有步骤的基础。

---

### 4.1 腾讯云 DNS 解析添加 A 记录

1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/) → **域名解析 DNSPod** → 选择你的域名
2. 点击「添加记录」，添加两条：

| 主机记录 | 记录类型 | 记录值        | 说明                    |
| -------- | -------- | ------------- | ----------------------- |
| `@`      | A        | 服务器公网 IP | 主域名 `yourdomain.com` |
| `www`    | A        | 服务器公网 IP | `www.yourdomain.com`    |

- TTL：默认 600（10 分钟）即可
- 解析生效通常需要几分钟到几十分钟（受 TTL 影响）

### 4.2 验证域名解析

在**本地电脑**执行：

```bash
dig yourdomain.com +short
nslookup yourdomain.com
```

能解析出你的服务器公网 IP 即成功。（部分网络禁 ping，以 dig/nslookup 结果为准。）

### 4.3 服务器上创建项目目录

SSH 登录 `deploy` 用户后：

```bash
sudo mkdir -p /opt/blog
sudo chown -R deploy:deploy /opt/blog
cd /opt/blog
```

> 选 `/opt/blog` 是 Linux 约定（第三方应用放 `/opt`）。你也可用 `~/blog`，自行统一即可。

### 4.4 规划目录结构（本步只建目录，文件第 4 步填充）

```bash
mkdir -p /opt/blog/{mysql/data,halo/data,nginx/conf.d,nginx/ssl}
```

最终结构（第 4 步前预览）：

```
/opt/blog/
├── docker-compose.yml      # 第4步创建：编排 halo + mysql + nginx
├── mysql/
│   └── data/              # MySQL 数据持久化（重要，不能丢）
├── halo/
│   └── data/              # Halo 数据（配置文件、上传等）
└── nginx/
    ├── conf.d/
    │   └── blog.conf      # 第5步：反向代理配置
    └── ssl/               # 第6步：放证书
```

### 4.5 ⚠️ 重要：ICP 备案（大陆节点必看）

腾讯云大陆节点服务器，**域名必须完成 ICP 备案**才能通过 80/443 端口对外访问，否则会被拦截。

- 未备案期间：可暂时用 **服务器公网 IP** 直接访问测试（先不依赖域名）
- 域名访问会被腾讯云拦截（提示需备案）
- 备案入口：腾讯云控制台 → 网站备案，需准备身份证/营业执照，审核通常 1–2 周
- **建议现在就提交备案**，它不阻塞后续部署（第 4–5 步可先用 IP 测试），但决定你最终能否用域名对外访问

# 五、第 4 步：部署 Halo + MySQL（Docker Compose）

> 前置：第 2 步 Docker 已就绪，第 3 步 `/home/exmaterial/blog` 目录已建。
> 说明：域名尚未注册，本步先用**服务器公网 IP** 测试访问。Nginx 反代（第 5 步）、HTTPS（第 6 步）待域名就绪后做。

---

### 5.1 编写 docker-compose.yml

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

### 5.2 放行 8090 端口

> ⚠️ 腾讯云有**两层**防火墙：① 系统 UFW；② 腾讯云**安全组**。两层都要放通，否则外部访问不通。

系统层：

```bash
sudo ufw allow 8090/tcp
```

腾讯云控制台 → 该实例 → **安全组** → 入站规则 → 添加：协议端口 `TCP:8090`，来源 `0.0.0.0/0`。

> 此 8090 为临时测试端口，第 5 步 Nginx 上线后建议关闭。

如果**非云服务器**，为**轻量应用服务器**的话，参考如下

**腾讯云控制台 → 轻量应用服务器 → 选择你的实例 → 防火墙** 

### 5.3 启动

```bash
cd /home/exmaterial/blog
docker compose up -d        # 后台启动
docker compose ps           # 查看容器状态（STATUS 应为 healthy/running）
docker compose logs -f halo # 看启动日志，Ctrl+C 退出
```

### 5.4 验证访问

浏览器打开 `http://你的公网IP:8090`，首次进入初始化页面（创建管理员账号、站点标题等）。

### 5.5 常见排错

- **容器起不来**：`docker compose logs halodb` / `docker compose logs halo` 看错误
- **Halo 连不上 MySQL**：确认三个密码一致、`halodb` 健康（等十几秒）
- **端口不通**：检查 UFW 是否放行 8090，以及**腾讯云安全组**是否放通 8090
- **初始化页面打不开**：确认 `halo` 容器 healthy（`docker compose ps`）





[Wasteland-builder (ExMaterial)](https://github.com/Wasteland-builder)
