# New-API Docker 构建脚本使用说明

## 📋 脚本概述

本项目提供了两个Docker构建脚本：

1. **`docker-build.sh`** - 完整的生产级构建脚本
2. **`docker-build-dev.sh`** - 简化的开发构建脚本

## 🚀 快速开始

### 1. 配置环境变量（可选）

```bash
# 复制配置文件
cp docker.env.example docker.env

# 编辑配置文件
nano docker.env
```

### 2. 本地开发构建

```bash
# 使用开发脚本快速构建
./docker-build-dev.sh

# 或使用完整脚本本地构建
./docker-build.sh
```

### 3. 生产环境构建

```bash
# 构建指定版本并推送
./docker-build.sh v1.0.0 --push

# 构建多平台镜像并推送
./docker-build.sh --all-platforms --push
```

## 📚 详细使用说明

### docker-build.sh 主要参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `<version>` | 指定版本号 | `v1.0.0` |
| `--push` | 推送到远程仓库 | `./docker-build.sh --push` |
| `--all-platforms` | 构建多平台镜像 | `./docker-build.sh --all-platforms` |
| `--dev` | 开发模式构建 | `./docker-build.sh --dev` |
| `--registry=<url>` | 指定镜像仓库 | `./docker-build.sh --registry=my-registry.com` |

### 使用示例

```bash
# 本地构建最新版本
./docker-build.sh

# 本地构建指定版本
./docker-build.sh v1.2.3

# 构建并推送到阿里云仓库
./docker-build.sh v1.2.3 --push

# 构建多平台镜像（amd64 + arm64）并推送
./docker-build.sh v1.2.3 --all-platforms --push

# 开发模式构建
./docker-build.sh --dev

# 指定其他镜像仓库
./docker-build.sh --registry=your-registry.com/namespace --push
```

## 🔧 配置说明

### docker.env 环境变量

```bash
# 阿里云镜像仓库配置
DOCKER_REGISTRY=crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3

# 默认版本标签
TAG=latest
```

### 项目结构要求

脚本假设以下项目结构：
```
new-api/
├── Dockerfile          # 多阶段构建文件
├── web/                # 前端代码目录
│   ├── package.json
│   └── bun.lock
├── main.go             # Go 主程序
├── go.mod              # Go 模块文件
├── VERSION             # 版本文件（可自动生成）
├── docker-build.sh     # 构建脚本
└── docker.env          # 环境变量配置
```

## 🐳 运行构建的镜像

### 基本运行

```bash
docker run -d --name new-api \
  -p 3000:3000 \
  -v ./data:/data \
  -v ./logs:/app/logs \
  -e TZ=Asia/Shanghai \
  new-api:latest
```

### 使用 docker-compose（推荐）

参考项目根目录的 `docker-compose.yml` 文件。

## 🔍 故障排除

### 常见问题

1. **Docker 未运行**
   ```
   错误: Docker 未运行，请先启动 Docker Desktop
   ```
   解决：启动 Docker Desktop 或 Docker 服务

2. **权限问题**
   ```bash
   chmod +x docker-build.sh
   chmod +x docker-build-dev.sh
   ```

3. **网络问题**
   如果推送到阿里云仓库失败，请检查：
   - 网络连接
   - 阿里云镜像仓库登录状态
   ```bash
   docker login crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com
   ```

4. **构建失败**
   检查 Dockerfile 和项目依赖是否正确。

## 📝 开发工作流建议

### 日常开发
```bash
# 1. 代码修改后快速构建测试
./docker-build-dev.sh

# 2. 运行测试
docker run --rm -p 3000:3000 new-api:dev-latest
```

### 发布流程
```bash
# 1. 本地测试
./docker-build.sh v1.x.x

# 2. 测试无误后推送
./docker-build.sh v1.x.x --push

# 3. 生产部署
# 使用 CI/CD 或手动部署
```

## 🔐 安全注意事项

1. **不要在 docker.env 中存储敏感信息**
2. **使用 .gitignore 忽略 docker.env 文件**
3. **定期更新基础镜像以获取安全补丁**
4. **在生产环境中使用具体版本号，避免使用 latest 标签**

## 📞 支持

如有问题，请查看：
1. 项目 README.md
2. Docker 官方文档
3. 提交 Issue 到项目仓库