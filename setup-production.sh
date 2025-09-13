#!/bin/bash
# New-API 生产环境配置生成脚本

set -e

echo "🔧 New-API 生产环境配置生成器"
echo "================================"

# 检查是否已存在配置文件
if [ -f "docker.env" ]; then
    echo "⚠️  发现现有的 docker.env 文件"
    read -p "是否要备份并重新生成？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv docker.env docker.env.backup.$(date +%Y%m%d_%H%M%S)
        echo "✅ 已备份现有配置文件"
    else
        echo "❌ 取消配置生成"
        exit 0
    fi
fi

# 复制模板
if [ -f "docker.env.production" ]; then
    cp docker.env.production docker.env
    echo "✅ 复制生产环境模板"
else
    echo "❌ 找不到 docker.env.production 模板文件"
    exit 1
fi

# 生成安全密钥
echo ""
echo "🔐 生成安全配置..."

# 检查openssl是否可用
if command -v openssl &> /dev/null; then
    SESSION_SECRET="newapi-session-$(openssl rand -base64 32 | tr -d '\n' | tr '/' '_' | tr '+' '-')"
    ADMIN_TOKEN="sk-$(openssl rand -hex 20)"
else
    # 如果没有openssl，使用date和随机数
    SESSION_SECRET="newapi-session-$(date +%s)-$(shuf -i 1000-9999 -n 1)"
    ADMIN_TOKEN="sk-$(date +%s)$(shuf -i 100000-999999 -n 1)"
fi

# 更新配置文件 - 使用不同的分隔符避免特殊字符冲突
sed -i "s|SESSION_SECRET=your-production-session-secret-key-change-this|SESSION_SECRET=${SESSION_SECRET}|" docker.env
sed -i "s|INITIAL_ROOT_TOKEN=sk-your-initial-admin-token-change-this|INITIAL_ROOT_TOKEN=${ADMIN_TOKEN}|" docker.env

echo "✅ 已生成安全密钥"

# 显示生成的配置
echo ""
echo "📋 生成的安全配置:"
echo "SESSION_SECRET: ${SESSION_SECRET}"
echo "INITIAL_ROOT_TOKEN: ${ADMIN_TOKEN}"

# 获取用户输入的可选配置
echo ""
echo "🔧 可选配置（按回车使用默认值）:"

# 询问镜像版本
read -p "镜像版本 (默认: latest): " VERSION
if [ -n "$VERSION" ]; then
    sed -i "s|TAG=latest|TAG=${VERSION}|" docker.env
    echo "✅ 设置镜像版本: $VERSION"
fi

# 询问端口
read -p "服务端口 (默认: 8999): " PORT
if [ -n "$PORT" ]; then
    sed -i "s|NEW_API_PORT=8999|NEW_API_PORT=${PORT}|" docker.env
    echo "✅ 设置服务端口: $PORT"
fi

# 询问是否修改数据库密码
echo ""
read -p "是否要修改数据库密码？当前: man@2025 (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -s -p "请输入新的MySQL密码: " NEW_DB_PASSWORD
    echo ""
    if [ -n "$NEW_DB_PASSWORD" ]; then
        # 转义特殊字符并更新配置文件中的密码
        ESCAPED_OLD_PASSWORD="man@2025"
        ESCAPED_NEW_PASSWORD=$(echo "$NEW_DB_PASSWORD" | sed 's/[[\.*^$()+?{|]/\\&/g')
        sed -i "s|${ESCAPED_OLD_PASSWORD}|${NEW_DB_PASSWORD}|g" docker.env
        echo "✅ 已更新数据库密码"
        echo ""
        echo "⚠️  重要提醒："
        echo "   请同时修改 docker-compose.yml 中的 MYSQL_ROOT_PASSWORD"
        echo "   修改命令："
        echo "   sed -i 's|MYSQL_ROOT_PASSWORD: 123456|MYSQL_ROOT_PASSWORD: ${NEW_DB_PASSWORD}|' docker-compose.yml"
    fi
fi

# 显示最终配置
echo ""
echo "📄 最终配置文件预览:"
echo "===================="
cat docker.env | grep -E "(DOCKER_REGISTRY|TAG|NEW_API_PORT|SESSION_SECRET|INITIAL_ROOT_TOKEN|MYSQL_ROOT_PASSWORD)" | head -6

echo ""
echo "✅ 配置文件生成完成: docker.env"
echo ""
echo "📋 下一步操作:"
echo "1. 检查并编辑 docker.env 配置文件"
echo "2. 登录阿里云镜像仓库: docker login crpi-appxm8pdgvw49jw2.cn-hangzhou.personal.cr.aliyuncs.com"
echo "3. 部署服务: ./deploy.sh"
echo "4. 验证部署: ./manage.sh status"
echo ""
echo "🔐 重要提醒:"
echo "- 请妥善保存生成的密钥信息"
echo "- 首次登录管理面板使用 INITIAL_ROOT_TOKEN"
echo "- 部署后请及时修改管理员密码"