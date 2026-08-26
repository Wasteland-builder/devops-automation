# 一、初次建立仓库

```bash
# 1. 在 GitHub 网页上新建一个空仓库（不要勾选 Readme，保持完全空白）
# 2. 在本地你的目录下执行
git init
git add .
git commit -m "init: 交付运维自动化脚本体系"
git branch -M main
git remote add origin git@github.com:你的用户名/devops-automation.git  # 推荐走 SSH 免密
git push -u origin main
```

# 二、同步仓库

**电脑 B（同步数据）：**

- 不要从网页下载 Zip，因为那样会丢失 `.git` 历史。
- 执行：`git clone git@github.com:你的用户名/devops-automation.git`

**日常同步习惯（关键）：**
运维工作经常临时改脚本，为了防止两台电脑冲突（Merge Conflict），建议养成 **“下班前 Push，上班前 Pull”** 的习惯。

- 电脑 A 改完：`git add .` -> `git commit -m "更新磁盘清理逻辑"` -> `git push`
- 电脑 B 上班：`git pull`