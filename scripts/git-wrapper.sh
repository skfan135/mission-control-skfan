#!/bin/bash
# Git 自动重试和错误处理脚本

set -e

# 配置
MAX_ATTEMPTS=3
RETRY_DELAY=3
GIT_CMD="$@"
LOG_FILE="/root/.openclaw/workspace/memory/git-errors.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 记录错误
log_error() {
    local error_msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $error_msg" >> "$LOG_FILE"
}

# 检测错误类型
detect_error_type() {
    local output="$1"
    
    if [[ "$output" == *"Connection reset by peer"* ]]; then
        echo "connection_reset"
    elif [[ "$output" == *"Permission denied"* ]]; then
        echo "permission_denied"
    elif [[ "$output" == *"Resource not accessible"* ]]; then
        echo "resource_inaccessible"
    elif [[ "$output" == *"Repository not found"* ]]; then
        echo "repo_not_found"
    elif [[ "$output" == *"fatal: unable to access"* ]]; then
        echo "network_error"
    else
        echo "unknown"
    fi
}

# 提供修复建议
provide_fix() {
    local error_type="$1"
    
    case "$error_type" in
        "connection_reset")
            echo -e "${YELLOW}建议：网络连接不稳定，正在重试...${NC}"
            ;;
        "permission_denied"|"resource_inaccessible")
            echo -e "${YELLOW}建议：检查 PAT 权限或重新认证${NC}"
            echo "运行：./scripts/auto-fix-auth.sh github"
            ;;
        "network_error")
            echo -e "${YELLOW}建议：检查网络连接或使用 SSH${NC}"
            ;;
        "repo_not_found")
            echo -e "${YELLOW}建议：确认仓库存在或创建新仓库${NC}"
            echo "运行：gh repo create repo-name --public"
            ;;
        *)
            echo -e "${YELLOW}未知错误，请检查详细日志${NC}"
            ;;
    esac
}

# 执行 git 命令并重试
attempt=1
last_output=""

echo "🔄 执行: git $GIT_CMD"

while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo -n "尝试 $attempt/$MAX_ATTEMPTS... "
    
    # 执行命令并捕获输出
    if output=$(git $GIT_CMD 2>&1); then
        # 成功
        echo -e "${GREEN}✓ 成功${NC}"
        
        # 如果是 push，更新统计
        if [[ "$GIT_CMD" == *push* ]]; then
            echo "✨ 代码已推送到远程仓库"
        fi
        
        exit 0
    else
        echo -e "${RED}✗ 失败${NC}"
        last_output="$output"
        
        # 分析错误
        error_type=$(detect_error_type "$output")
        log_error "Attempt $attempt failed: $output"
        
        if [ $attempt -lt $MAX_ATTEMPTS ]; then
            provide_fix "$error_type"
            echo "等待 $RETRY_DELAY 秒后重试..."
            sleep $RETRY_DELAY
            ((attempt++))
        fi
    fi
done

# 所有尝试都失败了
echo -e "\n${RED}❌ 错误：所有重试都失败了${NC}"
echo -e "${YELLOW}错误类型：${NC} $error_type"
echo -e "${YELLOW}最后输出：${NC} $last_output"
echo -e "${YELLOW}日志位置：${NC} $LOG_FILE"

# 提供进一步建议
echo -e "\n${GREEN}修复建议：${NC}"
provide_fix "$error_type"

# 如果是认证问题，提供快速修复命令
if [[ "$error_type" == "permission_denied" || "$error_type" == "resource_inaccessible" ]]; then
    echo -e "\n${YELLOW}快速修复命令：${NC}"
    echo "1. 检查当前认证状态："
    echo "   gh auth status"
    echo ""
    echo "2. 重新认证："
    echo "   echo \"\$GITHUB_TOKEN\" | gh auth login --with-token"
fi

exit 1