# New-API 线上部署配置指南

## 🎯 问题解决

您遇到的配置冲突问题已经解决！以下是完整的线上部署步骤。

## 📋 当前配置状态

您的 `docker-compose.yml` 使用：
- 数据库名：`new-api`
- MySQL用户：`root`
- MySQL密码：`man@2025`
- 应用端口：`8999`

## 🚀 线上部署步骤

### 第一步：准备配置文件

```bash
# 复制生产环境配置模板
cp docker.env.production docker.env

# 编辑配置文件
nano docker.env
```

**必须修改的安全配置：**
```bash
# 修改会话密钥（重要！）
SESSION_SECRET=your-unique-production-session-secret-$(date +%s)

# 修改初始管理员令牌（重要！）
INITIAL_ROOT_TOKEN=sk-newapi-admin-$(openssl rand -hex 16)

# 确认数据库密码
MYSQL_ROOT_PASSWORD=man@2025
```

### 第二步：登录阿里云镜像仓库

```bash
# 登录阿里云镜像仓库
docker login crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com
# 输入用户名：铅笔头科技
# 输入密码：[您的阿里云仓库密码]
```

### 第三步：部署服务

```bash
# 使用您构建的镜像部署
./deploy.sh latest compose

# 或指定特定版本
./deploy.sh v1.0.0 compose
```

### 第四步：验证部署

```bash
# 检查服务状态
./manage.sh status

# 检查健康状态
./manage.sh health

# 查看日志
./manage.sh logs 50
```

## 🔧 配置文件详解

### docker.env 配置说明

```bash
# === 镜像配置 ===
DOCKER_REGISTRY=crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3
TAG=latest                    # 或您构建的版本号

# === 服务配置 ===
NEW_API_PORT=8999            # 与docker-compose.yml匹配

# === 数据库配置（与docker-compose.yml匹配）===
SQL_DSN=root:man@2025@tcp(mysql:3306)/new-api
MYSQL_ROOT_PASSWORD=man@2025
MYSQL_DATABASE=new-api

# === Redis配置 ===
REDIS_CONN_STRING=redis://redis

# === 安全配置（生产环境必须修改）===
SESSION_SECRET=your-unique-session-secret
INITIAL_ROOT_TOKEN=sk-your-admin-token
```

## 🔒 安全配置建议

### 1. 生成安全的密钥

```bash
# 生成会话密钥
echo "SESSION_SECRET=newapi-$(openssl rand -base64 32)"

# 生成管理员令牌
echo "INITIAL_ROOT_TOKEN=sk-$(openssl rand -hex 20)"
```

### 2. 数据库安全（建议）

如果要提高安全性，可以修改数据库密码：

```bash
# 1. 停止服务
docker-compose down

# 2. 删除数据卷（注意：会丢失数据！）
docker volume rm new-api_mysql_data

# 3. 修改密码
# 在 docker-compose.yml 中修改 MYSQL_ROOT_PASSWORD
# 在 docker.env 中修改相应的 SQL_DSN 和 MYSQL_ROOT_PASSWORD

# 4. 重新部署
./deploy.sh
```

## 📝 部署后检查清单

### ✅ 服务检查
- [ ] 容器都在运行：`docker-compose ps`
- [ ] API响应正常：`curl http://localhost:8999/api/status`
- [ ] 管理面板可访问：`http://your-server:8999/panel`

### ✅ 安全检查
- [ ] SESSION_SECRET 已修改
- [ ] INITIAL_ROOT_TOKEN 已修改
- [ ] 防火墙只开放必要端口
- [ ] 数据目录权限正确

### ✅ 功能检查
- [ ] 数据库连接正常
- [ ] Redis连接正常
- [ ] 日志记录正常
- [ ] 文件上传正常

## 🔄 更新流程

### 更新到新版本

```bash
# 1. 构建新版本镜像（在开发机器上）
./docker-build.sh v1.1.0 --push

# 2. 在服务器上更新
./deploy.sh v1.1.0 compose

# 3. 验证更新
./manage.sh health
```

### 回滚到之前版本

```bash
# 回滚到指定版本
./deploy.sh v1.0.0 compose
```

## 🚨 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   # 查看日志
   ./manage.sh logs 100
   
   # 检查配置
   docker-compose config
   ```

2. **数据库连接失败**
   ```bash
   # 检查MySQL容器
   docker logs mysql
   
   # 验证连接字符串
   echo $SQL_DSN
   ```

3. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep 8999
   
   # 修改端口（在docker-compose.yml中）
   ports:
     - "9999:3000"  # 改为其他端口
   ```

## 📞 技术支持

如果遇到问题：
1. 检查 `./manage.sh status` 输出
2. 查看 `./manage.sh logs` 详细日志
3. 确认配置文件是否正确
4. 验证网络和防火墙设置