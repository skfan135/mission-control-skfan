#!/bin/bash
# 推送到 GitHub 的脚本

set -e

REPO_NAME="mission-control-${USER:-openclaw}"
GITHUB_USER="${GITHUB_USER:-}"

# 检查是否有 GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN 环境变量未设置"
    echo "请设置 GitHub Personal Access Token:"
    echo "  1. 访问: https://github.com/settings/tokens"
    echo "  2. 生成新的 token (需要 repo 权限)"
    echo "  3. 设置环境变量: export GITHUB_TOKEN=your_token"
    exit 1
fi

echo "🚀 准备推送到 GitHub..."

# 创建 GitHub 仓库
echo "📝 创建仓库..."
if [ -n "$GITHUB_USER" ]; then
    curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user/repos" \
        -d "{
            \"name\": \"$REPO_NAME\",
            \"description\": \"Mission Control - AI Task Management Dashboard\",
            \"private\": false,
            \"has_issues\": true,
            \"has_projects\": true,
            \"has_wiki\": true
        }"
    
    # 添加远程仓库
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
else
    echo "⚠️  未设置 GITHUB_USER，您需要手动创建仓库并添加 remote"
    exit 1
fi

# 推送代码
echo "📤 推送代码..."
git push -u origin master

# 启用 GitHub Pages
echo "🌐 启用 GitHub Pages..."
curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/pages" \
    -d '{
        "source": {
            "branch": "master",
            "path": "/"
        }
    }'

echo "✅ 完成！"
echo "📍 仓库地址: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "🌐 Pages 地址: https://$GITHUB_USER.github.io/$REPO_NAME"
echo ""
echo "下一步："
echo "1. 访问您的 Pages 地址查看仪表板"
echo "2. 复制 data/tasks.json 到您的本地进行修改"
echo "3. 设置 webhook 实现实时同步"