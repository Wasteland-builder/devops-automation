# 第 7 步：Git + GitHub Actions 自动部署

> 前置：第 4–5 步已就绪，项目在 `/home/exmaterial/blog`。
> Halo 是预构建镜像，"部署" = 拉取新镜像并重启。数据都在 Docker volume，重启不丢。
> 本步实现：push 代码到 GitHub → 自动 SSH 上服务器执行 `docker compose pull && up -d`。

---

### 7.1 在服务器初始化 Git 仓库

```bash
cd /home/exmaterial/blog
git init
cat > .gitignore <<'EOF'
halo/
mysql/
backups/
nginx/ssl/
.env
EOF
git add docker-compose.yml nginx/ .gitignore
git commit -m "init blog stack"
```
> 只提交配置（compose、nginx 配置），**不要提交数据库和上传数据**。

### 7.2 推到 GitHub

在 GitHub 新建空仓库 `my-blog`，然后：

```bash
git remote add origin git@github.com:你的用户名/my-blog.git
git branch -M main
git push -u origin main
```

### 7.3 配置仓库 Secrets

GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret，添加：
- `SERVER_HOST`：服务器公网 IP
- `SERVER_USER`：`exmaterial`
- `SSH_PRIVATE_KEY`：你本地用于登录服务器的**私钥**内容（公钥已放服务器；若还没密钥，本地 `ssh-keygen` 生成一对）

### 7.4 写工作流 `.github/workflows/deploy.yml`

```yaml
name: Deploy Blog
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: SSH 部署
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /home/exmaterial/blog
            docker compose pull
            docker compose up -d
```

### 7.5 验证

改一下 `docker-compose.yml` 里的 Halo 版本号（如 `2.20` → 更新版本），`git push` 后到 GitHub Actions 页面看任务是否跑绿，再访问博客确认已更新。

> 进阶：可加「先备份数据库再部署」的 step，提升安全性。

---

## 操作记录

| 步骤 | 完成日期 | 备注/问题 |
|---|---|---|
| 7.1 初始化仓库 | | |
| 7.2 推 GitHub | | |
| 7.3 配置 Secrets | | |
| 7.4 写工作流 | | |
| 7.5 验证 | | |
