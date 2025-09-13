#!/bin/bash
# MincodeOpenApi 项目镜像构建和推送脚本
# 构建应用镜像、Redis镜像、MySQL镜像并推送到阿里云私有仓库

set -e

# 阿里云镜像仓库配置
REGISTRY="crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3"
USERNAME="铅笔头科技"

# 版本标签
VERSION=${1:-$(date +%Y%m%d%H%M%S)}
LATEST_TAG="latest"

# 可选：是否跳过容器内前端构建（默认 false）。
# 用法： ./build-push.sh 20250913 true  => 第二个参数为 true 时跳过。
SKIP_WEB_BUILD=${2:-false}

if [ "$SKIP_WEB_BUILD" = "true" ]; then
    echo "🧱 跳过容器内前端构建，开始本地预构建 web/dist ..."
    if command -v bun >/dev/null 2>&1; then
        pushd web >/dev/null
        DISABLE_ESLINT_PLUGIN='true' VITE_REACT_APP_VERSION=$VERSION bun run build
        popd >/dev/null
    else
        echo "❌ 未找到 bun，请先安装 bun 或不要使用跳过模式"
        exit 1
    fi
fi

echo "=================================================="
echo "🚀 MincodeOpenApi 项目镜像构建和推送"
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

# 1. 构建 MincodeOpenApi 应用镜像
echo ""
echo "📦 构建 MincodeOpenApi 应用镜像..."
docker build \
    --platform linux/amd64 \
    --build-arg SKIP_WEB_BUILD=${SKIP_WEB_BUILD} \
    -t "${REGISTRY}/mincode-openapi:${VERSION}" \
    -t "${REGISTRY}/mincode-openapi:${LATEST_TAG}" \
    --push \
    .

echo "✅ MincodeOpenApi 应用镜像构建完成"

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
echo "   - ${REGISTRY}/mincode-openapi:${VERSION}"
echo "   - ${REGISTRY}/mincode-openapi:${LATEST_TAG}"
echo "   - ${REGISTRY}/redis:7-alpine"
echo "   - ${REGISTRY}/redis:${LATEST_TAG}"
echo "   - ${REGISTRY}/mysql:8.2"
echo "   - ${REGISTRY}/mysql:${LATEST_TAG}"
echo "=================================================="