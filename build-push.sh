#!/bin/bash
# New-API 项目镜像构建和推送脚本
# 构建应用镜像、Redis镜像、MySQL镜像并推送到阿里云私有仓库

set -e

# 阿里云镜像仓库配置
REGISTRY="crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3"
USERNAME="铅笔头科技"

# 版本标签
VERSION=${1:-$(date +%Y%m%d%H%M%S)}
LATEST_TAG="latest"

echo "=================================================="
echo "🚀 New-API 项目镜像构建和推送"
echo "镜像仓库: ${REGISTRY}"
echo "版本标签: ${VERSION}"
echo "=================================================="

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 错误: Docker 未运行，请先启动 Docker"
    exit 1
fi

# 登录到阿里云容器镜像服务
echo "🔐 登录阿里云镜像仓库..."
docker login --username="${USERNAME}" "${REGISTRY%%/*}"

# 1. 构建 New-API 应用镜像
echo ""
echo "📦 构建 New-API 应用镜像..."
docker build \
    --platform linux/amd64,linux/arm64 \
    -t "${REGISTRY}/new-api:${VERSION}" \
    -t "${REGISTRY}/new-api:${LATEST_TAG}" \
    --push \
    .

echo "✅ New-API 应用镜像构建完成"

# 2. 推送 Redis 镜像
echo ""
echo "📦 推送 Redis 镜像..."
docker pull redis:7-alpine
docker tag redis:7-alpine "${REGISTRY}/redis:7-alpine"
docker tag redis:7-alpine "${REGISTRY}/redis:latest"
docker push "${REGISTRY}/redis:7-alpine"
docker push "${REGISTRY}/redis:latest"
echo "✅ Redis 镜像推送完成"

# 3. 推送 MySQL 镜像
echo ""
echo "📦 推送 MySQL 镜像..."
docker pull mysql:8.2
docker tag mysql:8.2 "${REGISTRY}/mysql:8.2"
docker tag mysql:8.2 "${REGISTRY}/mysql:latest"
docker push "${REGISTRY}/mysql:8.2"
docker push "${REGISTRY}/mysql:latest"
echo "✅ MySQL 镜像推送完成"

echo ""
echo "=================================================="
echo "🎉 所有镜像构建和推送完成！"
echo ""
echo "📋 推送的镜像："
echo "   - ${REGISTRY}/new-api:${VERSION}"
echo "   - ${REGISTRY}/new-api:${LATEST_TAG}"
echo "   - ${REGISTRY}/redis:7-alpine"
echo "   - ${REGISTRY}/redis:${LATEST_TAG}"
echo "   - ${REGISTRY}/mysql:8.2"
echo "   - ${REGISTRY}/mysql:${LATEST_TAG}"
echo "=================================================="