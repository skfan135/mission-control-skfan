#!/bin/bash
# 设置 GitHub Webhook 的脚本

set -e

REPO_OWNER="skfan135"
REPO_NAME="mission-control-skfan"
WEBHOOK_URL="https://your-gateway-url.com/webhook/github-mission-control"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-mission-control-secret}"

echo "🔗 设置 GitHub Webhook for Mission Control"
echo "======================================"

# 生成随机 secret（如果未设置）
if [ "$WEBHOOK_SECRET" = "mission-control-secret" ]; then
    WEBHOOK_SECRET=$(openssl rand -hex 16)
    echo "🔐 生成的 Webhook Secret: $WEBHOOK_SECRET"
    echo "⚠️  保存这个 secret，后面会用到！"
fi

# 创建 webhook
echo "📡 创建 webhook..."
RESPONSE=$(gh api -X POST repos/$REPO_OWNER/$REPO_NAME/hooks \
    -f config.url="$WEBHOOK_URL" \
    -f config.content_type=json \
    -f config.secret="$WEBHOOK_SECRET" \
    -f events='["push"]' \
    --jq '.')

WEBHOOK_ID=$(echo $RESPONSE | jq -r '.id')
echo "✅ Webhook 创建成功，ID: $WEBHOOK_ID"

# 测试 webhook
echo ""
echo "📤 发送测试 ping..."
gh api -X POST repos/$REPO_OWNER/$REPO_NAME/hooks/$WEBHOOK_ID/pings

echo ""
echo "🎉 Webhook 设置完成！"
echo ""
echo "下一步："
echo "1. 配置您的 OpenClaw Gateway 中的 webhook 接收器"
echo "2. 设置 webhook secret: $WEBHOOK_SECRET"
echo "3. 确保端口开放且可访问"
echo ""
echo "Webhook URL: $WEBHOOK_URL"
echo "需要修改 URL 的话，使用这个命令："
echo "gh api -X PATCH repos/$REPO_OWNER/$REPO_NAME/hooks/$WEBHOOK_ID -f config.url=NEW_URL"