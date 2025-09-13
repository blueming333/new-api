#!/bin/bash
# New-API Docker镜像构建和推送脚本

set -e  # 遇到错误立即退出

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

# 加载环境变量
if [ -f docker.env ]; then
  echo "加载 docker.env 文件中的环境变量..."
  export $(cat docker.env | grep -v '#' | xargs)
else
  echo "Warning: docker.env 文件不存在，使用默认值。"
  # 设置默认值
  export DOCKER_REGISTRY="crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com/blueming3"
  export TAG=$(date +%Y%m%d%H%M%S)
fi

# 初始化参数
PUSH_IMAGE=false  # 默认不推送镜像，仅本地构建
ALL_PLATFORMS=false
VERSION=${TAG:-latest}
PLATFORMS="linux/amd64"  # 默认只构建amd64
BUILD_TYPE="production"  # production|development

# 处理命令行参数
for arg in "$@"
do
  if [ "$arg" == "--push" ]; then
    PUSH_IMAGE=true
  elif [ "$arg" == "--all-platforms" ]; then
    ALL_PLATFORMS=true
  elif [ "$arg" == "--dev" ]; then
    BUILD_TYPE="development"
  elif [[ "$arg" == --registry=* ]]; then
    DOCKER_REGISTRY="${arg#--registry=}"
  elif [[ "$arg" != --* ]]; then
    # 只有不是以--开头的参数才被视为版本号
    VERSION=$arg
  fi
done

# 根据参数决定平台
if [ "$ALL_PLATFORMS" == "true" ]; then
  PLATFORMS="linux/amd64,linux/arm64"
fi

# 使用处理后的变量
USE_VERSION=${VERSION}

# 设置镜像名称
NEW_API_IMAGE="${DOCKER_REGISTRY}/new-api:${USE_VERSION}"
NEW_API_IMAGE_LATEST="${DOCKER_REGISTRY}/new-api:latest"

# 确认环境变量
echo "=================================================="
echo "使用以下配置构建 New-API Docker镜像:"
echo "DOCKER REGISTRY: ${DOCKER_REGISTRY}"
echo "TAG/VERSION: ${USE_VERSION}"
echo "平台: ${PLATFORMS}"
echo "构建类型: ${BUILD_TYPE}"
echo "推送镜像: ${PUSH_IMAGE}"
echo "=================================================="

# 确保 buildx 构建器可用
echo "检查并配置 Docker buildx..."
if ! docker buildx inspect multiarch > /dev/null 2>&1; then
    docker buildx create --name multiarch --driver docker-container --use
else
    docker buildx use multiarch
fi
docker buildx inspect --bootstrap

# 生成版本信息
echo "📝 生成版本信息..."
if [ ! -f VERSION ] || [ -z "$(cat VERSION)" ]; then
    echo "v${USE_VERSION}" > VERSION
    echo "✅ 生成版本号: v${USE_VERSION}"
else
    echo "✅ 使用现有版本号: $(cat VERSION)"
fi

# 构建 New-API 镜像
echo "📦 开始构建 New-API 镜像，当前构建平台: ${PLATFORMS}"

# 构建参数
BUILD_ARGS=(
    --build-arg "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    --build-arg "GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    --build-arg "VERSION=$(cat VERSION)"
)

if [ "$BUILD_TYPE" == "development" ]; then
    BUILD_ARGS+=(--build-arg "NODE_ENV=development")
fi

if [ "$PUSH_IMAGE" == "true" ]; then
    # 如果需要推送，直接构建并推送
    echo "🚀 构建并推送 New-API 镜像到远程仓库..."
    docker buildx build --platform ${PLATFORMS} \
        --progress=plain \
        --push \
        -t ${NEW_API_IMAGE} \
        -t ${NEW_API_IMAGE_LATEST} \
        "${BUILD_ARGS[@]}" \
        -f Dockerfile \
        .
    echo "✅ New-API 镜像推送完成"
else
    # 不推送，仅构建本地镜像 (只构建当前平台)
    echo "🔨 仅构建本地 New-API 镜像..."
    docker buildx build --platform linux/amd64 \
        --progress=plain \
        --load \
        -t ${NEW_API_IMAGE} \
        -t ${NEW_API_IMAGE_LATEST} \
        "${BUILD_ARGS[@]}" \
        -f Dockerfile \
        .
    echo "✅ New-API 镜像本地构建完成"
fi

# 显示镜像信息
echo "=================================================="
echo "🎉 New-API 镜像构建完成:"
echo "- 镜像名称: ${NEW_API_IMAGE}"
echo "- 最新标签: ${NEW_API_IMAGE_LATEST}"
echo "- 平台支持: ${PLATFORMS}"
echo "- 构建类型: ${BUILD_TYPE}"
echo "=================================================="

# 如果是本地构建，显示镜像大小
if [ "$PUSH_IMAGE" == "false" ]; then
    echo "📋 本地镜像信息:"
    docker images | grep "new-api" | head -5
    echo ""
fi

# 判断是否已经推送镜像
if [ "$PUSH_IMAGE" == "true" ]; then
    echo "🚀 镜像已经推送到远程仓库！"
    echo ""
    echo "📝 拉取命令:"
    echo "docker pull ${NEW_API_IMAGE}"
    echo "docker pull ${NEW_API_IMAGE_LATEST}"
    echo ""
    echo "🚀 运行命令:"
    echo "docker run -d --name new-api -p 3000:3000 \\"
    echo "  -v ./data:/data \\"
    echo "  -v ./logs:/app/logs \\"
    echo "  -e TZ=Asia/Shanghai \\"
    echo "  ${NEW_API_IMAGE}"
else
    echo "🔨 镜像构建完成。如需推送镜像，请使用参数 --push"
    echo "例如: ./docker-build.sh ${USE_VERSION} --push"
    echo "或: ./docker-build.sh --push (使用默认版本号)"
    echo ""
    echo "🚀 本地运行命令:"
    echo "docker run -d --name new-api -p 3000:3000 \\"
    echo "  -v ./data:/data \\"
    echo "  -v ./logs:/app/logs \\"
    echo "  -e TZ=Asia/Shanghai \\"
    echo "  ${NEW_API_IMAGE_LATEST}"
fi

echo "=================================================="
echo "📚 使用说明:"
echo "参数说明:"
echo "  <version>      指定版本号 (默认: 当前时间戳)"
echo "  --push         推送镜像到远程仓库"
echo "  --all-platforms 构建多平台镜像 (amd64+arm64)"
echo "  --dev          开发模式构建"
echo "  --registry=<url> 指定镜像仓库地址"
echo ""
echo "使用示例:"
echo "  ./docker-build.sh                    # 本地构建 latest"
echo "  ./docker-build.sh v1.0.0             # 本地构建指定版本"
echo "  ./docker-build.sh --push             # 构建并推送 latest"
echo "  ./docker-build.sh v1.0.0 --push      # 构建并推送指定版本"
echo "  ./docker-build.sh --all-platforms --push  # 多平台构建并推送"
echo "=================================================="