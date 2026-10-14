# 第 2 步：安装 Docker 与 Docker Compose

> 适用 Ubuntu 22.04。在 `deploy` 用户下执行（管理员命令加 `sudo`）。
> 本步安装容器运行时，后续 Halo / MySQL / Nginx / Uptime Kuma 全部跑在 Docker 里。

---

### 2.1 卸载旧版本（如没有会提示无此包，忽略即可）
```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
```

### 2.2 安装依赖与添加 Docker 官方仓库
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 2.3 安装 Docker 引擎与 Compose 插件
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2.4 启动并设置开机自启
```bash
sudo systemctl enable --now docker
```

### 2.5 让 deploy 用户免 sudo 使用 docker
```bash
sudo usermod -aG docker $USER
```
> 执行后**必须退出 SSH 重新登录**，`docker` 组权限才会生效。

### 2.6（推荐）配置腾讯云镜像加速
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

### 2.7 验证安装
```bash
docker version
docker compose version
docker run --rm hello-world
```
看到 `Hello from Docker!` 即成功。

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 2.1 卸载旧版 | | |
| 2.2 添加仓库 | | |
| 2.3 安装 Docker | | |
| 2.4 开机自启 | | |
| 2.5 deploy 加 docker 组 | | |
| 2.6 镜像加速 | | |
| 2.7 验证 hello-world | | |
