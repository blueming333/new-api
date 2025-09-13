#!/bin/bash
# New-API 服务管理脚本

set -e

# 检查参数
if [ $# -eq 0 ]; then
    echo "New-API 服务管理脚本"
    echo ""
    echo "使用方法: $0 <命令> [参数]"
    echo ""
    echo "可用命令:"
    echo "  status          查看服务状态"
    echo "  logs [lines]    查看日志 (默认显示最后50行)"
    echo "  restart         重启服务"
    echo "  stop            停止服务"
    echo "  start           启动服务"
    echo "  update [version] 更新服务到指定版本"
    echo "  backup          备份数据"
    echo "  clean           清理未使用的镜像和容器"
    echo "  health          健康检查"
    echo "  stats           显示资源使用情况"
    echo ""
    echo "示例:"
    echo "  $0 status                    # 查看状态"
    echo "  $0 logs 100                  # 查看最后100行日志"
    echo "  $0 update v1.2.3             # 更新到v1.2.3版本"
    echo "  $0 backup                    # 备份数据"
    exit 1
fi

COMMAND=$1
PARAM=$2

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker 未运行，请先启动 Docker"
        exit 1
    fi
}

# 检查容器是否存在
check_container() {
    if ! docker ps -a --format "{{.Names}}" | grep -q "^new-api$"; then
        echo "❌ new-api 容器不存在"
        return 1
    fi
    return 0
}

# 确定compose命令
get_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

case $COMMAND in
    "status")
        echo "📊 New-API 服务状态"
        echo "===================="
        
        if check_container; then
            echo "🐳 容器状态:"
            docker ps --filter "name=new-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
            
            echo ""
            echo "💾 资源使用:"
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" new-api 2>/dev/null || echo "容器未运行"
        else
            echo "❌ 容器不存在"
        fi
        
        # 检查Compose服务
        COMPOSE_CMD=$(get_compose_cmd)
        if [ -n "$COMPOSE_CMD" ] && [ -f "docker-compose.yml" ]; then
            echo ""
            echo "🔄 Docker Compose 服务:"
            $COMPOSE_CMD ps 2>/dev/null || echo "Docker Compose 服务未运行"
        fi
        ;;
        
    "logs")
        check_docker
        LINES=${PARAM:-50}
        
        echo "📝 查看 New-API 日志 (最后 $LINES 行)"
        echo "================================"
        
        if check_container; then
            docker logs new-api --tail $LINES -f
        else
            echo "❌ 容器不存在"
            exit 1
        fi
        ;;
        
    "restart")
        check_docker
        echo "🔄 重启 New-API 服务"
        
        if check_container; then
            docker restart new-api
            echo "✅ 服务重启完成"
            
            # 等待服务就绪
            sleep 3
            if curl -fsS "http://localhost:3000/api/status" > /dev/null 2>&1; then
                echo "✅ 服务健康检查通过"
            else
                echo "⚠️ 服务可能还在启动中，请稍后检查"
            fi
        else
            echo "❌ 容器不存在，请先部署服务"
            exit 1
        fi
        ;;
        
    "stop")
        check_docker
        echo "🛑 停止 New-API 服务"
        
        if check_container; then
            docker stop new-api
            echo "✅ 服务已停止"
        else
            echo "❌ 容器不存在"
        fi
        ;;
        
    "start")
        check_docker
        echo "🚀 启动 New-API 服务"
        
        if check_container; then
            docker start new-api
            echo "✅ 服务已启动"
            
            # 等待服务就绪
            sleep 3
            if curl -fsS "http://localhost:3000/api/status" > /dev/null 2>&1; then
                echo "✅ 服务健康检查通过"
            else
                echo "⚠️ 服务可能还在启动中，请稍后检查"
            fi
        else
            echo "❌ 容器不存在，请先部署服务"
            exit 1
        fi
        ;;
        
    "update")
        check_docker
        VERSION=${PARAM:-latest}
        
        echo "📦 更新 New-API 到版本: $VERSION"
        echo "================================"
        
        if [ -f "./deploy.sh" ]; then
            ./deploy.sh $VERSION
        elif [ -f "./quick-deploy.sh" ]; then
            ./quick-deploy.sh "" $VERSION
        else
            echo "❌ 找不到部署脚本"
            exit 1
        fi
        ;;
        
    "backup")
        echo "💾 备份 New-API 数据"
        echo "===================="
        
        BACKUP_NAME="new-api-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
        
        if [ -d "data" ] || [ -d "logs" ]; then
            tar -czf $BACKUP_NAME data/ logs/ 2>/dev/null || true
            echo "✅ 备份完成: $BACKUP_NAME"
            echo "📁 备份大小: $(du -h $BACKUP_NAME | cut -f1)"
        else
            echo "❌ 找不到 data 或 logs 目录"
            exit 1
        fi
        ;;
        
    "clean")
        check_docker
        echo "🧹 清理未使用的 Docker 资源"
        echo "============================="
        
        echo "清理未使用的镜像..."
        docker image prune -f
        
        echo "清理未使用的容器..."
        docker container prune -f
        
        echo "清理未使用的网络..."
        docker network prune -f
        
        echo "✅ 清理完成"
        ;;
        
    "health")
        echo "🔍 New-API 健康检查"
        echo "==================="
        
        # 检查容器状态
        if check_container; then
            if docker ps --filter "name=new-api" --filter "status=running" | grep -q "new-api"; then
                echo "✅ 容器运行正常"
                
                # 检查API端点
                if curl -fsS "http://localhost:3000/api/status" > /dev/null 2>&1; then
                    echo "✅ API端点健康"
                    curl -s "http://localhost:3000/api/status" | head -3
                else
                    echo "❌ API端点无响应"
                fi
                
                # 检查日志是否有错误
                ERROR_COUNT=$(docker logs new-api --tail 100 2>&1 | grep -i "error\|exception\|fatal" | wc -l || echo "0")
                if [ "$ERROR_COUNT" -gt 0 ]; then
                    echo "⚠️ 发现 $ERROR_COUNT 个错误日志"
                else
                    echo "✅ 没有发现错误日志"
                fi
            else
                echo "❌ 容器未运行"
            fi
        else
            echo "❌ 容器不存在"
        fi
        ;;
        
    "stats")
        check_docker
        echo "📊 New-API 资源使用情况"
        echo "======================"
        
        if check_container; then
            echo "🐳 容器资源使用:"
            docker stats --no-stream new-api 2>/dev/null || echo "容器未运行"
            
            echo ""
            echo "💾 磁盘使用:"
            if [ -d "data" ]; then
                echo "数据目录: $(du -sh data/ | cut -f1)"
            fi
            if [ -d "logs" ]; then
                echo "日志目录: $(du -sh logs/ | cut -f1)"
            fi
            
            echo ""
            echo "🖥️ 系统资源:"
            echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')"
            echo "内存使用: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
            echo "磁盘使用: $(df -h . | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
        else
            echo "❌ 容器不存在"
        fi
        ;;
        
    *)
        echo "❌ 未知命令: $COMMAND"
        echo "使用 '$0' 查看帮助"
        exit 1
        ;;
esac