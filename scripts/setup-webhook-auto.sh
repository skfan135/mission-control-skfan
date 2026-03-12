#!/bin/bash
# 自动设置 OpenClaw webhook 的脚本

set -e

GITHUB_USER="skfan135"
REPO_NAME="mission-control-skfan"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -hex 16)}"
GATEWAY_URL="${OPENCLAW_GATEWAY_URL:-http://localhost:8080}"

echo "🔗 自动设置 Mission Control Webhook"
echo "===================================="

# 生成配置文件
echo ""
echo "📝 1. 生成 webhook 配置..."
mkdir -p ~/.clawdbot/hooks-transforms

# 创建 webhook transform
cat > ~/.clawdbot/hooks-transforms/github-mission-control.mjs << 'EOF'
import crypto from 'crypto';

export default {
    name: 'GitHub Mission Control Transform',
    description: 'Processes task changes from GitHub webhook',
    version: '1.0.0',
    
    async transform(context, request) {
        const { headers, body } = request;
        
        // Verify webhook signature
        const signature = headers['x-hub-signature-256'];
        const secret = context.secrets?.webhookSecret || process.env.GITHUB_WEBHOOK_SECRET;
        
        if (signature && secret) {
            const hmac = crypto.createHmac('sha256', secret);
            hmac.update(JSON.stringify(body));
            const expectedSignature = `sha256=${hmac.digest('hex')}`;
            
            if (signature !== expectedSignature) {
                throw new Error('Invalid webhook signature');
            }
        }
        
        // Handle push events
        if (headers['x-github-event'] === 'push') {
            const { ref, repository, commits } = body;
            
            // Check if push is to main/master branch
            if (!ref.endsWith('master') && !ref.endsWith('main')) {
                return { processed: false, message: 'Not a main branch push' };
            }
            
            // Check if tasks.json was modified
            const tasksModified = commits.some(commit => 
                commit.modified?.includes('data/tasks.json') ||
                commit.added?.includes('data/tasks.json')
            );
            
            if (tasksModified) {
                console.log('🎯 任务文件已更新，检查状态变化...');
                
                // Simulate task status checking
                // In real implementation, would fetch and compare old vs new
                
                return {
                    processed: true,
                    action: 'notify_agent',
                    data: {
                        message: '⚡ Mission Control 任务已更新！',
                        repository: repository.full_name,
                        pusher: body.pusher.name,
                        commit: commits[0]?.message
                    }
                };
            }
        }
        
        return { processed: false };
    }
};
EOF

echo "✅ Webhook transform 已创建"

# 更新 OpenClaw 配置
echo ""
echo "📝 2. 更新 OpenClaw 配置..."

# 确保 hooks 配置存在
cat >> ~/.clawdbot/hooks-config.json << EOF

{
    "github-mission-control": {
        "path": "~/.clawdbot/hooks-transforms/github-mission-control.mjs",
        "listen": {
            "host": "0.0.0.0",
            "port": 8080
        },
        "auth": {
            "token": "${WEBHOOK_SECRET}"
        }
    }
}
EOF

echo "✅ 配置文件已更新"

# 创建 GitHub webhook
echo ""
echo "📡 3. 创建 GitHub webhook..."

# 使用 gh CLI 创建 webhook
RESPONSE=$(gh api -X POST repos/${GITHUB_USER}/${REPO_NAME}/hooks \
    -f config.url="${GATEWAY_URL}/webhook/github-mission-control" \
    -f config.content_type=json \
    -f config.secret="${WEBHOOK_SECRET}" \
    -f events='["push"]' \
    --json id --jq '.id')

if [ -n "$RESPONSE" ]; then
    echo "✅ Webhook 创建成功，ID: $RESPONSE"
else
    echo "⚠️  Webhook 可能已存在"
fi

# 测试 webhook
echo ""
echo "📤 4. 测试 webhook 连接..."
if gh api --silent -X POST repos/${GITHUB_USER}/${REPO_NAME}/hooks/${RESPONSE}/pings; then
    echo "✅ 测试 ping 发送成功"
else
    echo "⚠️  测试失败，请检查 Gateway 是否运行"
fi

# 显示信息
echo ""
echo "🎉 设置完成！"
echo ""
echo "📊 配置信息："
echo "   Webhook Secret: ${WEBHOOK_SECRET}"
echo "   Gateway URL: ${GATEWAY_URL}"
echo "   Hook URL: ${GATEWAY_URL}/webhook/github-mission-control"
echo ""
echo "⚠️  请确保："
echo "   1. OpenClaw Gateway 正在运行"
echo "   2. 端口 8080 已开放"
echo "   3. 防火墙允许访问"
echo ""
echo "🔧 后续步骤："
echo "   1. 检查 Gateway 日志: openclaw gateway logs"
echo "   2. 测试任务同步"
echo "   3. 监控 webhook 触发情况"