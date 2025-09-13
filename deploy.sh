#!/bin/bash
# New-API 生产环境部署脚本 - 使用阿里云镜像

set -e  # 遇到错误立即退出

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker 未运行，请先启动 Docker"
    exit 1
fi

# 检查 docker-compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "错误: docker-compose 或 docker compose 未安装"
    exit 1
fi

# 确定使用的compose命令
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# 加载环境变量
if [ -f docker.env ]; then
  echo "加载 docker.env 文件中的环境变量..."
  export $(cat docker.env | grep -v '#' | xargs)
else
  echo "错误: docker.env 文件不存在"
  echo "请先创建 docker.env 文件并配置必要的环境变量"
  exit 1
fi

# 检查必要的环境变量
if [ -z "$DOCKER_REGISTRY" ]; then
  echo "错误: DOCKER_REGISTRY 未设置，请在 docker.env 中设置"
  exit 1
fi

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
  echo "警告: .env 文件不存在，将使用环境变量或默认配置"
else
  echo "检测到 .env 文件，将使用该文件进行部署"
fi

# 设置版本
VERSION=${1:-$TAG}
USE_VERSION=${VERSION:-latest}

# 部署模式：standalone (单机部署) 或 compose (完整部署)
DEPLOY_MODE=${2:-compose}

echo "=================================================="
echo "开始部署 New-API 服务..."
echo "使用镜像仓库: ${DOCKER_REGISTRY}"
echo "镜像版本: ${USE_VERSION}"
echo "部署模式: ${DEPLOY_MODE}"
echo "=================================================="

# 登录到阿里云容器镜像服务
echo "正在登录到阿里云镜像仓库..."
docker login --username="${DOCKER_REGISTRY_USERNAME:-铅笔头科技}" "${DOCKER_REGISTRY%%/*}"

# 设置镜像TAG环境变量供docker-compose使用
export TAG=$USE_VERSION
export NEW_API_IMAGE="${DOCKER_REGISTRY}/new-api:${USE_VERSION}"

# 拉取最新镜像
echo "=================================================="
echo "拉取最新镜像..."
echo "=================================================="

if [ "$DEPLOY_MODE" = "standalone" ]; then
    # 单机部署模式 - 仅部署New-API主服务
    echo "🚀 单机部署模式：仅部署New-API主服务"
    
    # 停止旧容器
    docker stop new-api 2>/dev/null || echo "容器 new-api 不存在或已停止"
    docker rm new-api 2>/dev/null || echo "容器 new-api 不存在"
    
    # 拉取镜像
    docker pull $NEW_API_IMAGE
    
    # 运行新容器
    echo "启动 New-API 容器..."
    docker run -d \
        --name new-api \
        --restart unless-stopped \
        -p ${NEW_API_PORT:-3000}:3000 \
        -v $(pwd)/data:/data \
        -v $(pwd)/logs:/app/logs \
        -e TZ=${TZ:-Asia/Shanghai} \
        -e SQL_DSN="${SQL_DSN:-}" \
        -e REDIS_CONN_STRING="${REDIS_CONN_STRING:-}" \
        -e SESSION_SECRET="${SESSION_SECRET:-}" \
        -e INITIAL_ROOT_TOKEN="${INITIAL_ROOT_TOKEN:-}" \
        -e ERROR_LOG_ENABLED="${ERROR_LOG_ENABLED:-true}" \
        -e STREAMING_TIMEOUT="${STREAMING_TIMEOUT:-300}" \
        -e GENERATE_DEFAULT_TOKEN="${GENERATE_DEFAULT_TOKEN:-true}" \
        --env-file .env 2>/dev/null || true \
        $NEW_API_IMAGE
        
    echo "✅ 单机部署完成"
    
else
        # 完整部署模式 - 使用docker-compose
    echo "🚀 完整部署模式：使用docker-compose部署"
    
    # 检查docker-compose文件
    if [ ! -f docker-compose.yml ]; then
        echo "错误: docker-compose.yml 文件不存在"
        exit 1
    fi
    
    # 更新docker-compose.yml中的镜像版本
    if [ "$USE_VERSION" != "latest" ]; then
        echo "📝 更新docker-compose.yml中的镜像版本为: ${NEW_API_IMAGE}"
        # 备份原文件
        cp docker-compose.yml docker-compose.yml.backup
        # 更新镜像版本
        sed -i "s|image: calciumion/new-api:.*|image: ${NEW_API_IMAGE}|g" docker-compose.yml
        sed -i "s|image: .*new-api:.*|image: ${NEW_API_IMAGE}|g" docker-compose.yml
    fi
    
    # 拉取镜像
    $COMPOSE_CMD pull
    
    # 启动服务
    $COMPOSE_CMD up -d
    
    echo "✅ 完整部署完成"
fi

# 等待服务启动
echo "=================================================="
echo "等待服务启动..."
echo "=================================================="

sleep 5

# 健康检查
HEALTH_CHECK_URL="http://localhost:${NEW_API_PORT:-3000}/api/status"
ATTEMPTS=0
MAX_ATTEMPTS=30

echo "进行健康检查: $HEALTH_CHECK_URL"

until curl -fsS "$HEALTH_CHECK_URL" > /dev/null; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo "❌ 健康检查超时，服务可能启动失败"
        
        # 显示错误日志
        if [ "$DEPLOY_MODE" = "standalone" ]; then
            echo "查看容器日志:"
            docker logs new-api --tail 20
        else
            echo "查看服务日志:"
            $COMPOSE_CMD logs --tail 20
        fi
        exit 1
    fi
    echo "等待服务就绪...($ATTEMPTS/$MAX_ATTEMPTS)"
    sleep 2
done

echo "✅ 健康检查通过"

# 显示服务状态
echo "=================================================="
echo "服务状态:"
echo "=================================================="

if [ "$DEPLOY_MODE" = "standalone" ]; then
    echo "New-API 容器状态:"
    docker ps --filter "name=new-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "容器资源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" new-api
else
    echo "Docker Compose 服务状态:"
    $COMPOSE_CMD ps
    
    echo ""
    echo "服务资源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --filter "label=com.docker.compose.project" --format "{{.Names}}" | head -5)
fi

# 显示部署信息
echo "=================================================="
echo "🎉 New-API 部署完成！"
echo ""
echo "📊 部署信息:"
echo "  📦 镜像版本: ${USE_VERSION}"
echo "  🐳 部署模式: ${DEPLOY_MODE}"
echo "  🌐 服务地址: http://localhost:${NEW_API_PORT:-3000}"
echo "  📝 健康检查: http://localhost:${NEW_API_PORT:-3000}/api/status"
echo "  📊 管理面板: http://localhost:${NEW_API_PORT:-3000}/panel"
echo ""
echo "🔧 管理命令:"
if [ "$DEPLOY_MODE" = "standalone" ]; then
    echo "  📊 查看状态: docker ps --filter name=new-api"
    echo "  📝 查看日志: docker logs new-api -f"
    echo "  🔄 重启服务: docker restart new-api"
    echo "  🛑 停止服务: docker stop new-api"
    echo "  🗑️  删除容器: docker rm -f new-api"
else
    echo "  📊 查看状态: $COMPOSE_CMD ps"
    echo "  📝 查看日志: $COMPOSE_CMD logs -f"
    echo "  🔄 重启服务: $COMPOSE_CMD restart"
    echo "  🛑 停止服务: $COMPOSE_CMD down"
    echo "  🗑️  完全清理: $COMPOSE_CMD down -v"
fi
echo ""
echo "📁 数据目录:"
echo "  💾 应用数据: $(pwd)/data"
echo "  📝 应用日志: $(pwd)/logs"
echo "=================================================="

# 显示快速操作提示
echo ""
echo "💡 快速操作提示:"
echo "  1. 查看实时日志: tail -f logs/*.log"
echo "  2. 备份数据: tar -czf backup-$(date +%Y%m%d).tar.gz data/ logs/"
echo "  3. 更新服务: $0 <new-version>"
echo "  4. 检查API状态: curl http://localhost:${NEW_API_PORT:-3000}/api/status"