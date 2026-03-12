#!/bin/bash
# 自动修复认证问题的脚本
# 当遇到 "No response requested" 或 "context canceled" 时运行

echo "🔧 诊断和修复认证问题..."

# 1. 检测问题类型
if [[ "$1" == *"github"* ]]; then
    echo "📋 检测到 GitHub 认证问题"
    echo "解决方案："
    echo "1. 在生成 GitHub Personal Access Token: https://github.com/settings/tokens"
    echo "2. 运行: echo \${GITHUB_TOKEN} | gh auth login --with-token"
    echo "3. 或设置环境变量: export GITHUB_TOKEN=your_token"
    
elif [[ "$1" == *"tailscale"* ]]; then
    echo "📋 检测到 Tailscale 认证问题"
    echo "解决方案："
    echo "1. 从 Tailscale 控制台生成 AuthKey: https://login.tailscale.com/admin/settings/keys"
    echo "2. 运行: tailscale up --auth-key=tskey-auth-xxxxx"
    echo "3. 或者用 headless 模式: tailscale up --accept-routes --accept-dns=false"
    
else
    echo "🔍 通用认证问题修复"
    echo "解决方案："
    echo "1. 检查是否需要非交互式参数"
    echo "2. 使用环境变量或 token 认证"
    echo "3. 查看 memory/2026-03-12.md 获取详细方案"
fi

# 记录问题
echo "$(date): 认证问题 - $1" >> /root/.openclaw/workspace/memory/auth-issues.log