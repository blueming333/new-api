#!/bin/bash
# New-API 快速部署脚本

set -e

echo "🚀 New-API 快速部署脚本"
echo "========================"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 设置默认配置
DEFAULT_REGISTRY="crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3"
DEFAULT_VERSION="latest"
DEFAULT_PORT="3000"

# 获取参数
REGISTRY=${1:-$DEFAULT_REGISTRY}
VERSION=${2:-$DEFAULT_VERSION}
PORT=${3:-$DEFAULT_PORT}

IMAGE_NAME="${REGISTRY}/new-api:${VERSION}"

echo "📝 部署配置:"
echo "  镜像仓库: ${REGISTRY}"
echo "  镜像版本: ${VERSION}"
echo "  服务端口: ${PORT}"
echo "  完整镜像: ${IMAGE_NAME}"
echo "========================"

# 停止并删除旧容器
echo "🛑 停止旧容器..."
docker stop new-api 2>/dev/null || echo "容器 new-api 不存在或已停止"
docker rm new-api 2>/dev/null || echo "容器 new-api 不存在"

# 拉取最新镜像
echo "📥 拉取镜像: ${IMAGE_NAME}"
docker pull $IMAGE_NAME

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data logs

# 启动新容器
echo "🚀 启动 New-API 容器..."
docker run -d \
    --name new-api \
    --restart unless-stopped \
    -p ${PORT}:3000 \
    -v $(pwd)/data:/data \
    -v $(pwd)/logs:/app/logs \
    -e TZ=Asia/Shanghai \
    -e ERROR_LOG_ENABLED=true \
    -e STREAMING_TIMEOUT=300 \
    -e GENERATE_DEFAULT_TOKEN=true \
    $IMAGE_NAME

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 健康检查
HEALTH_URL="http://localhost:${PORT}/api/status"
ATTEMPTS=0
MAX_ATTEMPTS=20

echo "🔍 进行健康检查: ${HEALTH_URL}"

until curl -fsS "$HEALTH_URL" > /dev/null 2>&1; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo "❌ 健康检查超时，查看容器日志:"
        docker logs new-api --tail 20
        exit 1
    fi
    echo "等待服务就绪...($ATTEMPTS/$MAX_ATTEMPTS)"
    sleep 2
done

echo "✅ 服务启动成功!"

# 显示容器状态
echo ""
echo "📊 容器状态:"
docker ps --filter "name=new-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 部署完成!"
echo "========================"
echo "🌐 访问地址: http://localhost:${PORT}"
echo "📝 健康检查: http://localhost:${PORT}/api/status"
echo "📊 管理面板: http://localhost:${PORT}/panel"
echo ""
echo "📝 常用命令:"
echo "  查看日志: docker logs new-api -f"
echo "  重启服务: docker restart new-api"
echo "  停止服务: docker stop new-api"
echo "  进入容器: docker exec -it new-api sh"
echo "========================"