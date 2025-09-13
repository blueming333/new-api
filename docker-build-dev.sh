#!/bin/bash
# New-API 快速构建脚本 (用于日常开发)

set -e

echo "🚀 New-API 快速构建脚本"
echo "========================"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 获取当前 Git 分支和提交
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date +%Y%m%d_%H%M%S)

# 生成开发版本号
DEV_VERSION="dev-${GIT_BRANCH}-${BUILD_TIME}"

# 设置镜像名称
IMAGE_NAME="new-api:${DEV_VERSION}"
LATEST_NAME="new-api:dev-latest"

echo "📝 构建信息:"
echo "  Git 分支: ${GIT_BRANCH}"
echo "  Git 提交: ${GIT_COMMIT}"
echo "  镜像名称: ${IMAGE_NAME}"
echo "========================"

# 生成版本文件
echo "v${DEV_VERSION}" > VERSION

# 构建镜像
echo "🔨 开始构建镜像..."
docker build \
    --build-arg "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg "GIT_COMMIT=${GIT_COMMIT}" \
    --build-arg "VERSION=v${DEV_VERSION}" \
    -t ${IMAGE_NAME} \
    -t ${LATEST_NAME} \
    -f Dockerfile \
    .

echo "✅ 构建完成!"
echo ""
echo "📋 镜像信息:"
docker images | grep "new-api" | head -3

echo ""
echo "🚀 快速运行命令:"
echo "docker run -d --name new-api-dev \\"
echo "  -p 3000:3000 \\"
echo "  -v \$(pwd)/data:/data \\"
echo "  -v \$(pwd)/logs:/app/logs \\"
echo "  -e TZ=Asia/Shanghai \\"
echo "  ${LATEST_NAME}"

echo ""
echo "🛑 停止和清理命令:"
echo "docker stop new-api-dev && docker rm new-api-dev"