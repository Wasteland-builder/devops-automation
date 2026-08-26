# 关于本仓库



# 目录解析

devops-automation/          # 仓库根目录
├── README.md               # 项目总览，写清楚这是干什么的
├── requirements.txt        # Python 依赖清单（方便重装环境）
├── .gitignore              # 【极其重要】后面专门讲
│
├── scripts/                # 【核心】所有可执行脚本放这里
│   ├── python/             # Python 脚本
│   │   ├── monitor/        # 监控类（如：检查CPU、内存、接口探活）
│   │   ├── deploy/         # 发布/回滚类（如：拉代码、重启服务）
│   │   ├── clean/          # 日志清理/磁盘清理类
│   │   └── utils/          # 通用公共库（如：封装的logging、发邮件函数）
│   └── shell/              # Shell 脚本
│       ├── system_init/    # 系统初始化（改内核参数、安装基础包）
│       ├── backup/         # 备份脚本
│       └── network/        # 网络检查/路由配置
│
├── configs/                # 【配置】服务器配置模板（非明文密码！）
│   ├── nginx/              # nginx 配置模板（.conf）
│   ├── docker/             # Dockerfile 或 docker-compose.yml
│   ├── k8s/                # Kubernetes 的 Deployment/Service yaml
│   └── env_templates/      # 环境变量模板（存放 .env.example，里面写占位符）
│
├── playbooks/              # 自动化编排（如果你学 Ansible 的话放这里）
│   ├── site.yml
│   └── roles/
│
└── notes/                  # 【笔记】你平时的学习记录
    ├── linux/              # Linux 内核/系统笔记
    ├── network/            # TCP/IP、DNS、网关笔记
    ├── python_learning/    # Python 学习笔记（jupyter_notebook 或 .md）
    ├── troubleshooting/    # 故障排查记录（重大故障复盘，这是运维的财富）
    └── images/             # 笔记引用的截图