# MincodeOpenApi 项目部署指南

## 🎯 概述

本项目提供了完整的 MincodeOpenApi 服务构建和部署解决方案，支持从本地构建到生产环境部署的全流程。

## 📁 项目结构

```
mincode-openapi/
├── build-push.sh          # 本地构建和推送脚本
├── setup-production.sh    # 生产环境配置脚本
├── docker-compose.yml     # Docker Compose 配置文件
├── start.sh               # 服务启动脚本（由 setup-production.sh 生成）
├── stop.sh                # 服务停止脚本（由 setup-production.sh 生成）
├── .env                   # 环境变量配置（由 setup-production.sh 生成）
├── data/                  # 数据存储目录
└── logs/                  # 日志存储目录
```

## 🚀 部署流程

### 步骤一：本地构建和推送镜像

在开发机上运行以下命令构建并推送所有镜像到阿里云私有仓库：

```bash
# 构建并推送所有镜像（应用、Redis、MySQL）
./build-push.sh

# 或指定版本号
./build-push.sh v1.0.0
```

**功能说明：**
- 构建 MincodeOpenApi 应用镜像（多平台支持）
- 推送 Redis 镜像到私有仓库
- 推送 MySQL 镜像到私有仓库
- 自动标记 latest 和版本号标签

### 步骤二：生产环境配置

在生产服务器上运行配置脚本：

```bash
# 运行生产环境配置向导
./setup-production.sh
```

**配置项说明：**
- 镜像仓库地址（默认：阿里云私有仓库）
- 服务端口配置（默认：8999）
- 数据库配置（自动生成安全密码）
- 安全密钥（自动生成）

### 步骤三：启动服务

```bash
# 启动所有服务
./start.sh
```

**启动过程：**
1. 登录阿里云镜像仓库
2. 拉取最新镜像
3. 启动 Docker Compose 服务
4. 显示服务状态和访问信息

### 步骤四：验证部署

- **访问地址：** `http://your-server:8999`
- **管理员登录：** 使用生成的 `INITIAL_ROOT_TOKEN`
- **健康检查：** `http://your-server:8999/api/status`

## 🛠️ 常用操作

### 服务管理

```bash
# 启动服务
./start.sh

# 停止服务
./stop.sh

# 查看服务状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 重启特定服务
docker compose restart mincode-openapi
```

### 数据管理

```bash
# 备份数据库
docker exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} mincode-openapi > backup.sql

# 进入应用容器
docker exec -it mincode-openapi /bin/sh

# 查看应用日志
tail -f logs/oneapi-*.log
```

### 镜像更新

```bash
# 拉取最新镜像并重启
docker compose pull && docker compose up -d
```

## 🔧 配置说明

### 环境变量配置 (.env)

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `REGISTRY` | 镜像仓库地址 | 阿里云私有仓库 |
| `NEW_API_PORT` | API 服务端口 | 8999 |
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码 | 自动生成 |
| `SESSION_SECRET` | 会话密钥 | 自动生成 |
| `INITIAL_ROOT_TOKEN` | 初始管理员Token | 自动生成 |

### 目录结构

- `data/` - 应用数据存储（持久化）
- `logs/` - 应用日志文件
- `mysql_data/` - MySQL 数据（Docker 卷）
- `redis_data/` - Redis 数据（Docker 卷）

## 🔒 安全注意事项

1. **保护敏感信息**
   - 妥善保管 `.env` 文件
   - 定期更换 `SESSION_SECRET`
   - 安全存储 `INITIAL_ROOT_TOKEN`

2. **网络安全**
   - 配置防火墙规则
   - 使用 HTTPS（需要反向代理）
   - 限制数据库端口访问

3. **数据备份**
   - 定期备份 MySQL 数据
   - 备份应用数据目录
   - 保留配置文件副本

## 🐛 故障排查

### 常见问题

1. **服务无法启动**
   ```bash
   # 检查Docker状态
   docker info
   
   # 检查端口占用
   netstat -tulpn | grep :8999
   
   # 查看详细错误
   docker compose logs
   ```

2. **镜像拉取失败**
   ```bash
   # 检查登录状态
   docker login crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com
   
   # 手动拉取测试
   docker pull crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3/mincode-openapi:latest
   ```

3. **数据库连接失败**
   ```bash
   # 检查数据库服务
   docker compose ps mysql
   
   # 查看数据库日志
   docker compose logs mysql
   ```

### 日志位置

- **应用日志：** `logs/oneapi-*.log`
- **Docker 日志：** `docker compose logs [service]`
- **系统日志：** `/var/log/docker.log`

## 📞 技术支持

如遇到问题，请检查：
1. 所有脚本是否有执行权限
2. Docker 服务是否正常运行
3. 网络连接是否正常
4. 阿里云镜像仓库访问权限

---

**注意：** 首次部署建议在测试环境验证完整流程后再在生产环境部署。