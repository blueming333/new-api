# New-API 部署脚本使用说明

## 📋 脚本概述

本项目提供了两个部署脚本，用于在线上服务器部署New-API：

1. **`deploy.sh`** - 完整的生产环境部署脚本
2. **`quick-deploy.sh`** - 快速单容器部署脚本

## 🚀 快速开始

### 方法一：快速部署（推荐新手）

```bash
# 使用默认配置快速部署
./quick-deploy.sh

# 指定镜像仓库和版本
./quick-deploy.sh your-registry.com/namespace v1.0.0 3000
```

### 方法二：完整部署

```bash
# 1. 配置环境变量
cp docker.env.deploy.example docker.env
nano docker.env

# 2. 部署服务
./deploy.sh v1.0.0 compose
```

## 📚 详细使用说明

### deploy.sh 参数说明

```bash
./deploy.sh [版本号] [部署模式]
```

| 参数 | 说明 | 可选值 | 默认值 |
|------|------|---------|---------|
| 版本号 | Docker镜像版本 | any | latest |
| 部署模式 | 部署方式 | standalone, compose | compose |

### 部署模式对比

| 模式 | 说明 | 适用场景 | 依赖 |
|------|------|----------|------|
| `standalone` | 单容器部署 | 简单部署、外部数据库 | 外部MySQL/Redis |
| `compose` | 完整部署 | 生产环境、一键部署 | docker-compose.yml |

### 使用示例

```bash
# 部署最新版本（完整模式）
./deploy.sh

# 部署指定版本
./deploy.sh v1.2.3

# 单容器部署
./deploy.sh latest standalone

# 快速部署到指定端口
./quick-deploy.sh your-registry.com/namespace latest 8080
```

## 🔧 配置说明

### docker.env 环境变量

```bash
# 镜像仓库配置
DOCKER_REGISTRY=crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3
DOCKER_REGISTRY_USERNAME=铅笔头科技

# 应用配置
NEW_API_PORT=3000
SESSION_SECRET=your-session-secret
INITIAL_ROOT_TOKEN=sk-your-admin-token

# 数据库配置（compose模式）
MYSQL_ROOT_PASSWORD=your-mysql-password
MYSQL_PASSWORD=your-user-password
```

### .env 应用配置文件

如果存在 `.env` 文件，脚本会自动加载其中的环境变量。

## 📁 文件结构

部署后的文件结构：
```
new-api/
├── deploy.sh              # 部署脚本
├── quick-deploy.sh         # 快速部署脚本
├── docker.env              # 环境变量配置
├── .env                    # 应用配置（可选）
├── docker-compose.yml      # Compose配置
├── data/                   # 应用数据目录
└── logs/                   # 日志目录
```

## 🔍 故障排除

### 常见问题

1. **Docker未运行**
   ```bash
   # 启动Docker服务
   sudo systemctl start docker
   ```

2. **镜像拉取失败**
   ```bash
   # 检查网络连接和仓库地址
   docker login your-registry.com
   ```

3. **端口冲突**
   ```bash
   # 检查端口占用
   sudo netstat -tlnp | grep :3000
   
   # 修改端口
   ./deploy.sh latest standalone
   # 或在docker.env中修改NEW_API_PORT
   ```

4. **健康检查失败**
   ```bash
   # 查看容器日志
   docker logs new-api --tail 50
   
   # 检查配置
   docker exec new-api env | grep -E "(SQL_DSN|REDIS|SESSION)"
   ```

5. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x deploy.sh quick-deploy.sh
   
   # 确保数据目录权限
   sudo chown -R $USER:$USER data logs
   ```

### 日志查看

```bash
# 查看容器日志
docker logs new-api -f

# 查看应用日志文件
tail -f logs/*.log

# 查看Compose服务日志
docker-compose logs -f
```

### 数据备份

```bash
# 备份数据
tar -czf backup-$(date +%Y%m%d).tar.gz data/ logs/

# 恢复数据
tar -xzf backup-20241201.tar.gz
```

## 🔄 更新服务

### 方法一：使用部署脚本更新

```bash
# 拉取新版本并更新
./deploy.sh v1.3.0

# 快速更新
./quick-deploy.sh your-registry.com/namespace v1.3.0
```

### 方法二：手动更新

```bash
# 停止服务
docker stop new-api

# 拉取新镜像
docker pull your-registry.com/namespace/new-api:v1.3.0

# 删除旧容器
docker rm new-api

# 启动新容器
./quick-deploy.sh your-registry.com/namespace v1.3.0
```

## 🔐 安全建议

1. **设置强密码**：修改数据库和Redis密码
2. **使用HTTPS**：配置反向代理和SSL证书
3. **防火墙配置**：只开放必要端口
4. **定期备份**：设置自动备份脚本
5. **监控日志**：配置日志监控和告警

## 📊 监控和维护

### 资源监控

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop
df -h
```

### 定期维护

```bash
# 清理未使用的镜像
docker image prune -f

# 清理未使用的卷
docker volume prune -f

# 查看磁盘使用
du -sh data/ logs/
```

## 📞 支持

如有问题，请：
1. 查看本文档的故障排除章节
2. 检查容器日志和应用日志
3. 提交Issue到项目仓库