#!/bin/bash
# New-API 生产环境配置脚本
# 生成 docker-compose 和应用启动所需的环境变量配置

set -e

echo "=================================================="
echo "� New-API 生产环境配置向导"
echo "=================================================="

# 生成安全密钥的函数
generate_key() {
    openssl rand -base64 32 | tr '/' '_' | tr '+' '-' | head -c 32
}

# 检查Docker是否运行
if ! docker --version > /dev/null 2>&1; then
    echo "❌ 警告: Docker 未安装或未在PATH中"
fi

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p data logs
chmod 755 data logs

echo ""
echo "📝 配置生产环境参数"
echo "如需使用默认值，直接按回车即可"
echo ""

# 镜像仓库配置
read -p "🔧 镜像仓库地址 [crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3]: " REGISTRY
REGISTRY=${REGISTRY:-crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3}

# 端口配置
read -p "🌐 New-API 服务端口 [8999]: " NEW_API_PORT
NEW_API_PORT=${NEW_API_PORT:-8999}

read -p "🌐 MySQL 端口 [3306]: " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

# 数据库配置
read -p "💾 MySQL 数据库名 [new-api]: " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-new-api}

read -p "🔑 MySQL root 密码 [随机生成]: " MYSQL_ROOT_PASSWORD
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_ROOT_PASSWORD=$(generate_key)
    echo "   已生成 MySQL 密码: $MYSQL_ROOT_PASSWORD"
fi

# 安全配置
echo ""
echo "🔐 生成安全密钥..."
SESSION_SECRET=$(generate_key)
INITIAL_ROOT_TOKEN="sk-$(generate_key)"

echo "   SESSION_SECRET: $SESSION_SECRET"
echo "   INITIAL_ROOT_TOKEN: $INITIAL_ROOT_TOKEN"

# 生成 .env 文件
echo ""
echo "� 生成 .env 文件..."
cat > .env << EOF
# ===== New-API 生产环境配置 =====
# 生成时间: $(date)

# ===== 镜像配置 =====
REGISTRY=${REGISTRY}
TAG=latest
REDIS_TAG=latest
MYSQL_TAG=latest

# ===== 服务端口配置 =====
NEW_API_PORT=${NEW_API_PORT}
MYSQL_PORT=${MYSQL_PORT}

# ===== 数据和日志目录 =====
DATA_DIR=./data
LOGS_DIR=./logs

# ===== 时区配置 =====
TZ=Asia/Shanghai

# ===== 数据库配置 =====
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
SQL_DSN=root:${MYSQL_ROOT_PASSWORD}@tcp(mysql:3306)/${MYSQL_DATABASE}

# ===== Redis 配置 =====
REDIS_CONN_STRING=redis://redis:6379/0

# ===== New-API 应用配置 =====
SESSION_SECRET=${SESSION_SECRET}
INITIAL_ROOT_TOKEN=${INITIAL_ROOT_TOKEN}
ERROR_LOG_ENABLED=true
STREAMING_TIMEOUT=300
GENERATE_DEFAULT_TOKEN=true
EOF

echo "✅ .env 文件已生成"

# 生成启动脚本
echo ""
echo "📄 生成启动脚本..."
cat > start.sh << 'EOF'
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
EOF

chmod +x start.sh

# 生成停止脚本
cat > stop.sh << 'EOF'
#!/bin/bash
# New-API 服务停止脚本

echo "🛑 停止 New-API 服务..."
docker compose down

echo "✅ 服务已停止"
EOF

chmod +x stop.sh

echo ""
echo "=================================================="
echo "🎉 生产环境配置完成！"
echo ""
echo "📋 生成的文件:"
echo "   - .env              环境变量配置文件"
echo "   - start.sh          服务启动脚本"
echo "   - stop.sh           服务停止脚本"
echo "   - data/             数据目录"
echo "   - logs/             日志目录"
echo ""
echo "� 下一步操作:"
echo "   1. 运行 ./start.sh 启动服务"
echo "   2. 访问 http://localhost:${NEW_API_PORT}"
echo "   3. 使用管理员Token登录: ${INITIAL_ROOT_TOKEN}"
echo ""
echo "=================================================="