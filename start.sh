#!/bin/bash
# New-API 服务启动脚本

set -e

echo "🚀 启动 New-API 服务..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 错误: Docker 未运行，请先启动 Docker"
    exit 1
fi

# 检查环境配置
if [ ! -f .env ]; then
    echo "❌ 错误: .env 文件不存在，请先运行 setup-production.sh"
    exit 1
fi

# 加载环境变量
source .env

# 登录阿里云镜像仓库
echo "🔐 登录阿里云镜像仓库..."
docker login --username="铅笔头科技" "${REGISTRY%%/*}"

# 拉取最新镜像
echo "📦 拉取最新镜像..."
docker compose pull

# 启动服务
echo "🚀 启动服务..."
docker compose up -d

# 检查服务状态
echo "📊 检查服务状态..."
sleep 5
docker compose ps

echo ""
echo "✅ 服务启动完成！"
echo "🌐 访问地址: http://localhost:${NEW_API_PORT}"
echo "🔑 管理员Token: ${INITIAL_ROOT_TOKEN}"
echo ""
echo "📋 常用命令:"
echo "   查看日志: docker compose logs -f"
echo "   停止服务: docker compose down"
echo "   重启服务: docker compose restart"